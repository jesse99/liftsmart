//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ProgramView: View {
    var program: Program
    var history: History
    
    var body: some View {
        NavigationView {
            List(0..<program.count) { i in
                NavigationLink(destination: WorkoutView(workout: self.program[i], history: self.history)) {
                    VStack(alignment: .leading) {
                        Text(self.program[i].name).font(.title)
                        Text(self.subTitle(i)).foregroundColor(self.subColor(i)).font(.headline) // 10+ Reps or As Many Reps As Possible
                    }
                }
            }
            .navigationBarTitle(Text(program.name + " Workouts"))
        }
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
    
    func subTitle(_ index: Int) -> String {
        if isWorkoutInProgress(index) {
            return "In progress"
        } else {
            return ""
        }
    }

    func subColor(_ index: Int) -> Color {
        if isWorkoutInProgress(index) {
            return .red
        } else {
            return .black
        }
    }

    // Returns the workouts being executed atm (but not those that have finished executing).
    func isWorkoutInProgress(_ index: Int) -> Bool {
        func numCompleted(_ workout: Workout) -> Int {
            var count = 0
            let calendar = Calendar.current
            for exercise in workout.exercises {
                if let completed = exercise.dateCompleted(history), calendar.isDate(completed, inSameDayAs: Date()) {
                    count += 1
                }
            }
            return count
        }

        let workout = self.program[index]
        let completed = numCompleted(workout)
        return completed > 0 && completed < workout.exercises.count
    }
}

struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(program: ProgramView_Previews.home(), history: ProgramView_Previews.history())
    }
    
    private static func home() -> Program {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise("Squats", "Body-weight Squat", modality)
        }
        
        func planks() -> Exercise { // TODO: this should be some sort of progression
            let durations = [
                DurationSet(secs: 60, restSecs: 90)!,
                DurationSet(secs: 60, restSecs: 90)!,
                DurationSet(secs: 60, restSecs: 90)!]
            let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise("Planks", "Front Plank", modality)
        }
        
        func curls() -> Exercise {
            let sets = Sets.maxReps(restSecs: [90, 90, 0])
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: 65))
        }

        let workouts = [
            Workout("Lower", [burpees(), squats()]),
            Workout("Upper", [planks(), curls()])]
        return Program("Split", workouts)
    }

    private static func history() -> History {
        let program = ProgramView_Previews.home()
        let history = History()
        history.append(program[0].exercises.first!)
        return history
    }
}
