import Foundation
import HealthKit
import os
import Observation
import SwiftUI

@Observable
class WorkoutManager: NSObject {
    static let shared = WorkoutManager()
    var workoutError: String?
    var isPreparing: Bool { isStarting || isRecovering || isEnding }
    private var isStarting = false
    private var isRecovering = false
    private var isEnding = false
    private var startAfterRecovery = false
    private var startAfterEnding = false
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    var timer: Timer?

    var running: Bool = false
    var heartRate: Double = 0
    var activeEnergy: Double = 0
    var elapsedTimeString: String = "00:00"

    let logger = Logger(subsystem: "com.antigravity.IronFive", category: "WorkoutManager")

    func requestAuthorization() {
        guard !DesignPreview.isEnabled else { return }
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let optionalTypes = [
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        ]
        let typesToRead = Set(optionalTypes.compactMap { $0 })

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                self.logger.info("HealthKit authorization successful.")
            } else if let error = error {
                self.logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }

    func startOrResumeWorkout() {
        if DesignPreview.isEnabled { running = true; return }
        guard !isEnding else { startAfterEnding = true; return }
        if let session = session {
            if session.state == .paused { session.resume() }
            return
        }
        if isStarting { return }
        recoverWorkout(startIfUnavailable: true)
    }

    func recoverWorkout(startIfUnavailable: Bool = false) {
        guard !DesignPreview.isEnabled else { return }
        guard session == nil, !isStarting, !isEnding else { return }
        startAfterRecovery = startAfterRecovery || startIfUnavailable
        guard !isRecovering else { return }
        isRecovering = true
        healthStore.recoverActiveWorkoutSession { recoveredSession, error in
            DispatchQueue.main.async {
                self.isRecovering = false
                let shouldStart = self.startAfterRecovery
                self.startAfterRecovery = false
                if let recoveredSession = recoveredSession {
                    self.attachRecoveredSession(recoveredSession)
                    if shouldStart && recoveredSession.state == .paused { recoveredSession.resume() }
                } else if let error = error {
                    self.workoutError = "Could not recover Apple Health workout: \(error.localizedDescription)"
                } else if shouldStart {
                    self.startWorkout()
                }
            }
        }
    }

    private func attachRecoveredSession(_ recoveredSession: HKWorkoutSession) {
        session = recoveredSession
        builder = recoveredSession.associatedWorkoutBuilder()
        recoveredSession.delegate = self
        builder?.delegate = self
        if builder?.dataSource == nil {
            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore, workoutConfiguration: recoveredSession.workoutConfiguration
            )
        }
        running = recoveredSession.state == .running
        updateHeartRate()
        updateActiveEnergy()
        updateElapsedTime()
        startTimer()
    }

    private func startWorkout() {
        guard session == nil, !isStarting, !isEnding else { return }
        isStarting = true
        heartRate = 0
        activeEnergy = 0
        elapsedTimeString = "00:00"
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            session?.delegate = self
            builder?.delegate = self

            let startDate = Date()
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { success, error in
                DispatchQueue.main.async {
                    self.isStarting = false
                    if success {
                        self.running = true
                        self.startTimer()
                    } else {
                        self.session?.end()
                        self.session = nil
                        self.builder = nil
                        self.workoutError = "Could not start Apple Health workout: \(error?.localizedDescription ?? "Unknown error")"
                    }
                }
            }
        } catch {
            isStarting = false
            workoutError = "Could not start Apple Health workout: \(error.localizedDescription)"
            logger.error("Failed to start workout session: \(error.localizedDescription)")
        }
    }

    private func updateElapsedTime() {
        guard let builder = builder else { return }
        let elapsed = Int(builder.elapsedTime)
        elapsedTimeString = String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }

    private func startTimer() {
        timer?.invalidate()
        updateElapsedTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    func pauseWorkout() {
        if DesignPreview.isEnabled { running = false; return }
        timer?.invalidate()
        timer = nil
        session?.pause()
    }

    func endWorkout() {
        if DesignPreview.isEnabled { running = false; return }
        guard !isEnding, let endingSession = session, let endingBuilder = builder else { return }
        isEnding = true
        timer?.invalidate()
        timer = nil
        endingSession.end()
        endingBuilder.endCollection(withEnd: Date()) { success, error in
            guard success else {
                self.completeEnding(error: error)
                return
            }
            endingBuilder.finishWorkout { _, error in
                self.completeEnding(error: error)
            }
        }
    }

    private func completeEnding(error: Error?) {
        DispatchQueue.main.async {
            self.running = false
            self.isEnding = false
            self.session = nil
            self.builder = nil
            if let error = error {
                self.workoutError = "Could not save Apple Health workout: \(error.localizedDescription)"
            }
            if self.startAfterEnding {
                self.startAfterEnding = false
                self.startOrResumeWorkout()
            }
        }
    }

}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Handle state changes if necessary
        DispatchQueue.main.async {
            guard self.session === workoutSession else { return }
            self.running = (toState == .running)
            if self.running {
                self.startTimer()
            } else if toState == .paused {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        logger.error("Workout session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            guard self.session === workoutSession else { return }
            self.workoutError = "Apple Health workout failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
           collectedTypes.contains(heartRateType) {
            DispatchQueue.main.async {
                self.updateHeartRate()
            }
        }
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           collectedTypes.contains(energyType) {
            DispatchQueue.main.async {
                self.updateActiveEnergy()
            }
        }
    }

    private func updateHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        if let statistics = builder?.statistics(for: heartRateType),
           let heartRate = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
            self.heartRate = heartRate
        }
    }

    private func updateActiveEnergy() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        if let statistics = builder?.statistics(for: energyType),
           let energy = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
            self.activeEnergy = energy
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Unused for MVP
    }
}
