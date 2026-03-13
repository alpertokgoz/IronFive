import SwiftUI

struct SetRowView: View {
    @Binding var workoutSet: WorkoutSet
    let isAMRAP: Bool
    var onComplete: () -> Void
    var onPlateCalc: () -> Void

    @FocusState private var isRepFieldFocused: Bool
    @State private var scale: CGFloat = 1.0
    @State private var showParticles = false
    @State private var showAmrapSheet = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onPlateCalc) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(String(format: "%.1f", workoutSet.weight))")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                        Text("kg")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundStyle(workoutSet.isCompleted ? .secondary : .primary)
                }
                .buttonStyle(.plain)

                if isAMRAP {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("AMRAP")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.orange)

                        if workoutSet.isCompleted {
                            Text("\(workoutSet.actualReps) REPS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("\(workoutSet.reps) REPS")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                handleCompletion()
            }) {
                ZStack {
                    // 1. Background Track
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .background(Circle().fill(Color.white.opacity(0.05)))

                    // 2. Filling Animation
                    Circle()
                        .fill(Color.green)
                        .scaleEffect(workoutSet.isCompleted ? 1.0 : 0.001)
                        .opacity(workoutSet.isCompleted ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: workoutSet.isCompleted)

                    // 3. Checkmark
                    if workoutSet.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.black)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // 4. Particles
                    if showParticles {
                        ParticleBurstView()
                    }
                }
                .frame(width: 44, height: 44)
                .scaleEffect(scale)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .sheet(isPresented: $showAmrapSheet) {
            AmrapInputView(reps: $workoutSet.actualReps) {
                showAmrapSheet = false
                if workoutSet.actualReps == 0 {
                    workoutSet.actualReps = Int(workoutSet.reps.replacingOccurrences(of: "+", with: "")) ?? 0
                }
                markCompleted()
            }
        }
    }

    private func handleCompletion() {
        if !workoutSet.isCompleted {
            if isAMRAP {
                showAmrapSheet = true
            } else {
                markCompleted()
            }
        } else {
            WKInterfaceDevice.current().play(.directionDown)
            withAnimation(.spring()) {
                workoutSet.isCompleted = false
                showParticles = false
            }
        }
    }

    private func markCompleted() {
        WKInterfaceDevice.current().play(.success)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 0.9
            workoutSet.isCompleted = true
            showParticles = true
            onComplete()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showParticles = false
        }
    }
}

struct ParticleBurstView: View {
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speedX: CGFloat
        var speedY: CGFloat
        let color: Color
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 4, height: 4)
                        .scaleEffect(p.scale)
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                for _ in 0..<12 {
                    let angle = Double.random(in: 0..<2 * .pi)
                    let speed = CGFloat.random(in: 10...30)
                    particles.append(Particle(
                        x: center.x,
                        y: center.y,
                        scale: CGFloat.random(in: 0.5...1.0),
                        opacity: 1,
                        speedX: cos(angle) * speed,
                        speedY: sin(angle) * speed,
                        color: [.green, .mint, .white].randomElement()!
                    ))
                }

                withAnimation(.easeOut(duration: 0.6)) {
                    for i in particles.indices {
                        particles[i].x += particles[i].speedX
                        particles[i].y += particles[i].speedY
                        particles[i].scale = 0
                        particles[i].opacity = 0
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct AmrapInputView: View {
    @Binding var reps: Int
    var onDone: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("How many reps?")
                .font(.system(size: 14, weight: .black, design: .rounded))

            HStack(spacing: 4) {
                Text("\(reps)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(isFocused ? .black : .accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isFocused ? Color.accentColor : Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .focusable()
                    .focused($isFocused)
                    .digitalCrownRotation($reps.toDouble(), from: 0, through: 50, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)

                Text("REPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .onAppear {
            isFocused = true
        }
    }
}

private extension Binding where Value == Int {
    func toDouble() -> Binding<Double> {
        return Binding<Double>(
            get: { Double(self.wrappedValue) },
            set: { self.wrappedValue = Int($0) }
        )
    }
}
