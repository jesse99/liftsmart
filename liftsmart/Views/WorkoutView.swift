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
    
    func label() -> String {
        var sets: [String] = []
        
        switch exercise.modality.sets {
        case .durations(let durations, _):
            sets = durations.map({$0.debugDescription})

        case .maxReps(let restSecs, _):
            if exercise.expected.reps.isEmpty {
                return "\(restSecs.count) sets"
            } else {
                let a: [String] = exercise.expected.reps.map({String($0)})
                return a.joined(separator: ", ") + " reps"
            }

        case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
            sets = worksets.map({$0.debugDescription})
        }
        
        if sets.count == 0 {
            return ""
        } else if sets.count == 1 {
            return sets[0]
        } else if sets.all({$0 == sets[0]}) {
            return "\(sets.count)x\(sets[0])"
        } else {
            return sets.joined(separator: ", ")
        }
    }
    
    func labelColor() -> Color {
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
            assert(false)
//            return AnyView(ExerciseRepRangesView(workout, exercise, history))

//      case .untimed(restSecs: let secs):
//          sets = Array(repeating: "untimed", count: secs.count)
        }
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutView(workout: program[0], history: history)
    }
}
