//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct WorkoutRow: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    @State var color: Color = .black
    
    init(workout: Workout, exercise: Exercise, history: History) {
        self.workout = workout
        self.exercise = exercise
        self.history = history
        self.color = labelColor()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.name)
                .font(.headline)
                .onAppear {self.color = self.labelColor()}  // bit of a hack to force WorkoutRow to reload when a nested view changes exercise state
                .foregroundColor(color)

            if !label().isEmpty {
                Text(label())
                    .font(.subheadline)
                    .foregroundColor(color)
            }
        }
    }
    
    private func label() -> String {
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
            sets = worksets.mapi(repsSetLabel)
            limit = 2
        }
        
        if sets.count == 0 {
            return ""
        } else if sets.count == 1 {
            return sets[0]
        } else if sets.all({$0 == sets[0]}) {
            return "\(sets.count)x\(sets[0])"
        } else {
            let prefix = sets.prefix(limit)
            let result = prefix.joined(separator: ", ")
            if prefix.count < sets.count {
                return result + ", ..."
            } else {
                return result
            }
        }
    }
    
    private func labelColor() -> Color {
        if exercise.recentlyCompleted(workout, history) {
            return .gray
        } else if exercise.inProgress(workout, history) {
            return .blue
        } else {
            return .black
        }
    }
    
    private func repsSetLabel(_ index: Int, _ workset: RepsSet) -> String {
        var result = ""
        
        let min = max(workset.reps.min, expectedReps(index) ?? 0)
        let max = workset.reps.max
        if let reps = RepRange(min: min, max: max), let set = RepsSet(reps: reps, percent: workset.percent, restSecs: workset.restSecs) {
            result = set.debugDescription
        }
        
        return result
    }
    
    func expectedReps(_ i: Int) -> Int? {
        return i < exercise.expected.reps.count ? exercise.expected.reps[i] : nil
    }
}

struct WorkoutView: View {
    var workout: Workout
    var history: History
    
    var body: some View {
        List(workout.exercises) { exercise in
            NavigationLink(destination: self.exerciseView(exercise)) {
                WorkoutRow(workout: self.workout, exercise: exercise, history: self.history)
            }
        }
        .navigationBarTitle(Text(workout.name + " Exercises"))
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
    static let reps1 = RepRange(min: 8, max: 12)!
    static let reps2 = RepRange(min: 6, max: 10)!
    static let reps3 = RepRange(min: 4, max: 6)!
    static let work1 = RepsSet(reps: reps1, percent: WeightPercent(0.8)!, restSecs: 60)!
    static let work2 = RepsSet(reps: reps2, percent: WeightPercent(0.9)!, restSecs: 60)!
    static let work3 = RepsSet(reps: reps3, percent: WeightPercent(1.0)!)!
    static let rsets = Sets.repRanges(warmups: [], worksets: [work1, work2, work3], backoffs: [])
    static let m1 = Modality(Apparatus.bodyWeight, rsets)
    static let ohp = Exercise("OHP", "OHP", m1, Expected(weight: 120.0, reps: [10, 8, 5]))
    
    static let msets = Sets.maxReps(restSecs: [60, 60, 60, 60, 60, 60], targetReps: 130)
    static let m2 = Modality(Apparatus.bodyWeight, msets)
    static let curls = Exercise("Curls", "Curls", m2, Expected(weight: 20.0, reps: [100]))

    static let set1 = DurationSet(secs: 90, restSecs: 60)!
    static let set2 = DurationSet(secs: 80, restSecs: 60)!
    static let set3 = DurationSet(secs: 70, restSecs: 60)!
    static let set4 = DurationSet(secs: 60, restSecs: 60)!
    static let set5 = DurationSet(secs: 50, restSecs: 60)!
    static let set6 = DurationSet(secs: 40, restSecs: 60)!
    static let set7 = DurationSet(secs: 30, restSecs: 60)!
    static let dsets = Sets.durations([set1, set2, set3, set4, set5, set6, set7], targetSecs: [])
    static let m3 = Modality(Apparatus.bodyWeight, dsets)
    static let planks = Exercise("Planks", "Planks", m3)
    static let workout = Workout("Strength", [ohp, curls, planks], day: nil)!

    static var previews: some View {
        WorkoutView(workout: workout, history: history)
    }
}
