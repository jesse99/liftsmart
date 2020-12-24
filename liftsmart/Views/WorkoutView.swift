//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var workoutEntryId = 0

struct WorkoutEntry: Identifiable {
    let id: Int
    let exercise: Exercise
    var label: String
    var color: Color

    init(_ workout: Workout, _ exercise: Exercise) {
        self.id = workoutEntryId
        self.exercise = exercise
        self.label = WorkoutEntry.getLabel(workout, exercise)
        self.color = WorkoutEntry.getColor(workout, exercise)
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
            return set.debugDescription
        }
        
        var sets: [String] = []
        var limit = 5
        
        switch exercise.modality.sets {
        case .durations(let durations, _):
            sets = durations.map({$0.debugDescription})

        case .maxReps(let restSecs, let targetReps):
            if exercise.expected.reps.isEmpty {
                if let target = targetReps {
                return "up to \(target) reps over \(restSecs.count) sets"
                } else {
                    return "\(restSecs.count) sets"
                }
            } else {
                return "\(exercise.expected.reps[0]) reps over \(restSecs.count) sets"
            }

        case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
            sets = worksets.mapi(getRepsLabel)
            limit = 2
        }
        
        if sets.count == 0 {
            return ""
        } else if sets.count == 1 {
            return sets[0]
        } else {
            let sets = dedupe(sets)
            let prefix = sets.prefix(limit)
            let result = prefix.joined(separator: ", ")
            if prefix.count < sets.count {
                return result + ", ..."
            } else {
                return result
            }
        }
    }
    
    private static func getColor(_ workout: Workout, _ exercise: Exercise) -> Color {
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
    var workout: Workout
    var history: History
    @State var entries: [WorkoutEntry] = []
    @State var editModal = false

    var body: some View {
        VStack {
            List(self.entries) {entry in
                NavigationLink(destination: self.exerciseView(entry.exercise)) {
                    VStack(alignment: .leading) {
                        Text(entry.exercise.name).font(.headline).foregroundColor(entry.color)
                        if !entry.label.isEmpty {
                            Text(entry.label).font(.subheadline).foregroundColor(entry.color)
                        }
                    }
                }
            }
            .navigationBarTitle(Text(workout.name + " Exercises"))
            .onAppear {self.refresh()}
            
            Divider()
            HStack {
                Spacer()
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal, onDismiss: self.refresh) {EditWorkoutView(workout: self.workout)}
            }
            .padding()
        }
    }
    
    func refresh() {
        entries = []
        for exercise in workout.exercises {
            if exercise.enabled {
                entries.append(WorkoutEntry(workout, exercise))
            }
        }
    }

    private func onEdit() {
        self.editModal = true
    }
    
    func exerciseView(_ exercise: Exercise) -> AnyView {
        switch exercise.modality.sets {
        case .durations(_, _):
            return AnyView(ExerciseDurationsView(workout, exercise, history))

        case .maxReps(_, _):
            return AnyView(ExerciseMaxRepsView(workout, exercise, history))

        case .repRanges(_, _, _):
            return AnyView(ExerciseRepRangesView(workout, exercise, history))

//      case .untimed(restSecs: let secs):
//          sets = Array(repeating: "untimed", count: secs.count)
        }
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static let reps1 = RepRange(min: 8, max: 12)
    static let reps2 = RepRange(min: 6, max: 10)
    static let reps3 = RepRange(min: 4, max: 6)
    static let work1 = RepsSet(reps: reps1, percent: WeightPercent(0.8), restSecs: 60)
    static let work2 = RepsSet(reps: reps2, percent: WeightPercent(0.9), restSecs: 60)
    static let work3 = RepsSet(reps: reps3, percent: WeightPercent(1.0))
    static let rsets = Sets.repRanges(warmups: [], worksets: [work1, work2, work3], backoffs: [])
    static let m1 = Modality(Apparatus.bodyWeight, rsets)
    static let ohp = Exercise("OHP", "OHP", m1, Expected(weight: 120.0, reps: [10, 10, 10]))
    
    static let msets = Sets.maxReps(restSecs: [60, 60, 60, 60, 60, 60], targetReps: 130)
    static let m2 = Modality(Apparatus.bodyWeight, msets)
    static let curls = Exercise("Curls", "Curls", m2, Expected(weight: 20.0, reps: [100]))

    static let set1 = DurationSet(secs: 90, restSecs: 60)
    static let set2 = DurationSet(secs: 80, restSecs: 60)
    static let set3 = DurationSet(secs: 70, restSecs: 60)
    static let set4 = DurationSet(secs: 60, restSecs: 60)
    static let set5 = DurationSet(secs: 50, restSecs: 60)
    static let set6 = DurationSet(secs: 40, restSecs: 60)
    static let set7 = DurationSet(secs: 30, restSecs: 60)
    static let dsets = Sets.durations([set1, set2, set3, set4, set5, set6, set7], targetSecs: [])
    static let m3 = Modality(Apparatus.bodyWeight, dsets)
    static let planks = Exercise("Planks", "Planks", m3)
    static let workout = createWorkout("Strength", [ohp, curls, planks], day: nil).unwrap()

    static var previews: some View {
        WorkoutView(workout: workout, history: history)
    }
}
