//  Created by Jesse Vorisek on 5/25/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

func home() -> Program {
    func burpees1() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Burpees 1", "Burpees", modality)
    }
    
    func squats1() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Squats 1", "Body-weight Squat", modality)
    }
    
    func burpees2() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 45, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Burpees 2", "Burpees", modality)
    }
    
    func squats2() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 45, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Squats 2", "Body-weight Squat", modality)
    }

    func burpees3() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 30, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Burpees 3", "Burpees", modality)
    }
    
    func squats3() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 30, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Squats 3", "Body-weight Squat", modality)
    }

    func burpees4() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 15, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Burpees 4", "Burpees", modality)
    }
    
    func squats4() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 15, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Squats 4", "Body-weight Squat", modality)
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
        return Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: 81))
    }

    let workouts = [Workout("Workout", [
        burpees1(), squats1(),
        burpees2(), squats2(),
        burpees3(), squats3(),
        burpees4(), squats4(),
        planks(), curls()])!]
    return Program("Home", workouts)
}

let program = home()
let history = History()
