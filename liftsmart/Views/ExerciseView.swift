//  Created by Jesse Jones on 4/11/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseView: View {
    let workoutIndex: Int
    let exerciseID: Int
    @ObservedObject var display: Display
    
    init(_ display: Display, _ workoutIndex: Int, _ exerciseID: Int) {
        self.display = display
        self.workoutIndex = workoutIndex
        self.exerciseID = exerciseID
    }
    
    var body: some View {
        getView()
    }
    
    func workout() -> Workout {
        return self.display.program.workouts[workoutIndex]
    }
    
    func exercise() -> Exercise {
        return self.workout().exercises.first(where: {$0.id == self.exerciseID})!
    }

    func getView() -> AnyView {
        switch exercise().modality.sets {
        case .durations(_, _):
            return AnyView(ExerciseDurationsView(display, workoutIndex, exerciseID))

        case .fixedReps(_):
            return AnyView(ExerciseFixedRepsView(display, workoutIndex, exerciseID))

        case .maxReps(_, _):
            return AnyView(ExerciseMaxRepsView(display, workoutIndex, exerciseID))

        case .repRanges(_, _, _):
            return AnyView(ExerciseRepRangesView(display, workoutIndex, exerciseID))

        case .repTarget(target: _, rest: _):
            return AnyView(ExerciseRepTargetView(display, workoutIndex, exerciseID))

        //      case .untimed(restSecs: let secs):
//          sets = Array(repeating: "untimed", count: secs.count)
        }
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex = 0
    static let workout = display.program.workouts[workoutIndex]
    static let exercise = workout.exercises.first(where: {$0.name == "Planks"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseView(display, workoutIndex, exercise.id)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
