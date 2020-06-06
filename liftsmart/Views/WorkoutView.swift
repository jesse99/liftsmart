//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct WorkoutRow: View {
    var exercise: Exercise

    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.name).font(.headline)
            if !label().isEmpty {
                Text(label()).font(.subheadline)
            }
        }
    }
    
    func label() -> String {
        var sets: [String] = []
        
        switch exercise.modality.sets {
        case .durations(let durations, _):
            sets = durations.map({$0.debugDescription})

        case .maxReps(_, _):
            break

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
}

struct WorkoutView: View {
    var workout: Workout
    
    var body: some View {
        List(workout.exercises) { exercise in
            NavigationLink(destination: self.exerciseView(exercise)) {
                WorkoutRow(exercise: exercise)
            }
        }
        .navigationBarTitle(Text(workout.name))
    }
    
    func exerciseView(_ exercise: Exercise) -> AnyView {
        switch exercise.modality.sets {
        case .durations(let durations, let targetDuration):
            return AnyView(ExerciseDurationsView(exercise))

        case .maxReps(_, _):
            return AnyView(Text("maxReps not implemented"))

        case .repRanges(_, _, _):
            return AnyView(Text("repRanges not implemented"))

//      case .untimed(restSecs: let secs):
//          sets = Array(repeating: "untimed", count: secs.count)
        }
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutView(workout: program[0])
    }
}
