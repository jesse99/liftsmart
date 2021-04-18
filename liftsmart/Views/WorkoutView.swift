//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var workoutEntryId = 0

struct WorkoutEntry: Identifiable {
    let id: Int
    let exercise: Exercise
    var label: String
    var color: Color

    init(_ workout: Workout, _ exercise: Exercise, _ history: History) {
        self.id = workoutEntryId
        self.exercise = exercise
        self.label = WorkoutEntry.getLabel(workout, exercise)
        self.color = WorkoutEntry.getColor(workout, exercise, history)
        workoutEntryId += 1
    }
    
    private static func getLabel(_ workout: Workout, _ exercise: Exercise) -> String {
        func getExpectedReps(_ i: Int) -> Int? {
            return i < exercise.expected.reps.count ? exercise.expected.reps[i] : nil
        }

        func getRepsLabel(_ index: Int, _ workset: RepsSet) -> String {
            let min = getExpectedReps(index) ?? workset.reps.min
            let max = workset.reps.max
            let reps = RepRange(min: min, max: max)
            let set = RepsSet(reps: reps, percent: workset.percent, restSecs: workset.restSecs)
            let suffix = weightSuffix(workset.percent, exercise.expected.weight)
            if !suffix.isEmpty {
                return set.reps.editable + suffix   // 3x5 @ 120 lbs
            } else {
                return set.reps.label               // 3x5 reps
            }
        }
        
        var sets: [String] = []
        var limit = 8

        var trailer = ""
        switch exercise.modality.sets {
        case .durations(let durations, _):
            sets = durations.map({$0.debugDescription})
            trailer = weightSuffix(WeightPercent(1.0), exercise.expected.weight)    // always the same for each set so we'll stick it at the end

        case .fixedReps(let worksets):
            sets = worksets.mapi(getRepsLabel)
            limit = 6

        case .maxReps(_, let targetReps):
            var label = ""
            if exercise.expected.reps.isEmpty {
                if let target = targetReps {
                    label = "up to \(target) total reps"
                }
            } else {
                label = "\(exercise.expected.reps[0]) total reps"
            }

            let suffix = weightSuffix(WeightPercent(1.0), exercise.expected.weight)
            if !suffix.isEmpty {
                return label + suffix
            } else {
                return label
            }

        case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
            sets = worksets.mapi(getRepsLabel)
            limit = 5
        }
        
        if sets.count == 0 {
            return ""
        } else if sets.count == 1 {
            return sets[0] + trailer
        } else {
            let sets = dedupe(sets)
            let prefix = sets.prefix(limit)
            let result = prefix.joined(separator: ", ")
            if prefix.count < sets.count {
                return result + ", ..."
            } else {
                return result + trailer
            }
        }
    }
    
    private static func getColor(_ workout: Workout, _ exercise: Exercise, _ history: History) -> Color {
        if exercise.recentlyCompleted(workout, history) {
            return .gray
        } else if exercise.inProgress(workout, history) {
            return .blue
        } else {
            return .black
        }
    }
}

struct WorkoutView: View {
    let workoutIndex: Int
    @State var editModal = false
    @ObservedObject var display: Display

    init(_ display: Display, _ index: Int) {
        self.display = display
        self.workoutIndex = index
    }

    var body: some View {
        VStack {
            List(self.getEntries()) {entry in
                NavigationLink(destination: ExerciseView(self.display, self.workoutIndex, entry.exercise.id)) {
                    VStack(alignment: .leading) {
                        Text(entry.exercise.name).font(.headline).foregroundColor(entry.color)
                        if !entry.label.isEmpty {
                            Text(entry.label).font(.subheadline).foregroundColor(entry.color)
                        }
                    }
                }
            }
            .navigationBarTitle(Text(workout().name + " Exercises" + self.display.edited))

            Divider()
            HStack {
                Spacer()
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditWorkoutView(self.display, self.workout())}
            }
            .padding()
        }
    }

    // Despite the fact that our state changes are quite coarse there are times when child
    // views are not rebuilt with the new versions of exercise and workout. It seems tough
    // to fix that especially given the opacity about when and how views are rebuilt. So
    // we'll just dodge the whole issue and have views grab whatever they need from the
    // current version of display.program.
    func workout() -> Workout {
        return self.display.program.workouts[workoutIndex]
    }

    private func onEdit() {
        self.editModal = true
    }
    
    private func getEntries() -> [WorkoutEntry] {
//        assert(display.program.workouts.first(where: {$0 === workout()}) != nil)  // gets a little wonky when switching programs
        var entries: [WorkoutEntry] = []
        for exercise in workout().exercises {
            if exercise.enabled {
                entries.append(WorkoutEntry(workout(), exercise, display.history))
            }
        }
        return entries
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        WorkoutView(display, 0)
    }
}
