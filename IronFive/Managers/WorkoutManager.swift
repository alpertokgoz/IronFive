import Foundation
import HealthKit
import os

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var running: Bool = false
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    
    let logger = Logger(subsystem: "com.antigravity.IronFive", category: "WorkoutManager")
    
    func requestAuthorization() {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                self.logger.info("HealthKit authorization successful.")
            } else if let error = error {
                self.logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func startWorkout() {
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
                if success {
                    DispatchQueue.main.async { self.running = true }
                }
            }
        } catch {
            logger.error("Failed to start workout session: \(error.localizedDescription)")
        }
    }
    
    func endWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { success, error in
            self.builder?.finishWorkout { workout, error in
                DispatchQueue.main.async {
                    self.running = false
                }
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle state changes if necessary
        DispatchQueue.main.async {
            self.running = (toState == .running)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        logger.error("Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        if collectedTypes.contains(HKQuantityType.quantityType(forIdentifier: .heartRate)!) {
            DispatchQueue.main.async {
                self.updateHeartRate()
            }
        }
        if collectedTypes.contains(HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!) {
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
