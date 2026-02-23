import SwiftUI
import SwiftData

struct WorkoutActiveView: View {
    let lift: MainLift
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Warmup
            VStack {
                Text("Warmup")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if workoutManager.running {
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                        Text(String(format: "%.0f BPM", workoutManager.heartRate))
                    }
                    .font(.caption)
                    .padding(.bottom, 4)
                }
                
                SetRowView(weight: "40%", reps: "5", isCompleted: .constant(false))
                SetRowView(weight: "50%", reps: "5", isCompleted: .constant(false))
                SetRowView(weight: "60%", reps: "3", isCompleted: .constant(false))
                
                Spacer()
            }
            .padding()
            .tabItem { Text("Warmup") }
            .tag(0)
            
            // 5/3/1 Main Work
            VStack {
                Text("\(lift.name) - 5/3/1")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Example hardcoded for 5s week
                SetRowView(weight: "65%", reps: "5", isCompleted: .constant(false))
                SetRowView(weight: "75%", reps: "5", isCompleted: .constant(false))
                SetRowView(weight: "85%", reps: "5+", isCompleted: .constant(false))
                
                Spacer()
            }
            .padding()
            .tabItem { Text("Main") }
            .tag(1)
            
            // FSL Supplemental
            VStack {
                Text("First Set Last (FSL)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ForEach(0..<5) { i in
                    SetRowView(weight: "65%", reps: "5", isCompleted: .constant(false))
                }
                
                Spacer()
            }
            .padding()
            .tabItem { Text("FSL") }
            .tag(2)
            
            // Accessories
            VStack {
                Text("Accessories")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add accessories in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Finish Workout") {
                    workoutManager.endWorkout()
                    // Add dismissal logic or navigate back
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
            .tabItem { Text("Accessories") }
            .tag(3)
        }
        .tabViewStyle(.page)
        .navigationTitle(lift.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            workoutManager.startWorkout()
        }
    }
}

struct SetRowView: View {
    let weight: String
    let reps: String
    @Binding var isCompleted: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(weight).font(.title3).fontWeight(.bold)
                Text("\(reps) Reps").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            
            Button(action: {
                isCompleted.toggle()
                // Auto start rest timer logic here
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutActiveView(lift: .squat)
}
