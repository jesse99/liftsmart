//  Created by Jesse Vorisek on 5/25/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

func home() -> Program {
    // https://www.defrancostraining.com/joe-ds-qlimber-11q-flexibility-routine/
    func formRolling() -> Exercise {
        let work = RepsSet(reps: RepRange(15)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Foam Rolling", "IT-Band Foam Roll", modality)
    }

    func ironCross() -> Exercise {
        let work = RepsSet(reps: RepRange(10)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Bent-knee Iron Cross", "Bent-knee Iron Cross", modality)
    }

    func vSit() -> Exercise {
        let work = RepsSet(reps: RepRange(15)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Roll-over into V-sit", "Roll-over into V-sit", modality)
    }

    func frog() -> Exercise {
        let work = RepsSet(reps: RepRange(10)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Rocking Frog Stretch", "Rocking Frog Stretch", modality)
    }

    func fireHydrant() -> Exercise {
        let work = RepsSet(reps: RepRange(10)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Fire Hydrant Hip Circle", "Fire Hydrant Hip Circle", modality)
    }

    func mountain() -> Exercise {
        let work = RepsSet(reps: RepRange(10)!, restSecs: 30)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Mountain Climber", "Mountain Climber", modality)
    }

    func cossack() -> Exercise {
        let work = RepsSet(reps: RepRange(10)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Cossack Squat", "Cossack Squat", modality)
    }

    func piriformis() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 30, restSecs: 0)!, DurationSet(secs: 30, restSecs: 0)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Piriformis Stretch", "Seated Piriformis Stretch", modality)
    }
    
    // Rehab
    func shoulderFlexion() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 8, max: 12)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Shoulder Flexion", "Single Shoulder Flexion", modality)
    }
    
    func bicepsStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 15, restSecs: 30)!,
            DurationSet(secs: 15, restSecs: 30)!,
            DurationSet(secs: 15, restSecs: 0)!]
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Biceps Stretch", "Wall Biceps Stretch", modality)
    }
    
    func externalRotation() -> Exercise {
        let work = RepsSet(reps: RepRange(15)!, restSecs: 0)!
        let sets = Sets.repRanges(warmups: [], worksets: [work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("External Rotation", "Lying External Rotation", modality)
    }
    
    func sleeperStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 30, restSecs: 30)!,
            DurationSet(secs: 30, restSecs: 30)!,
            DurationSet(secs: 30, restSecs: 0)!]
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Sleeper Stretch", "Sleeper Stretch", modality)
    }

    // https://www.builtlean.com/2012/04/10/dumbbell-complex
    // DBCircuit looks to be a harder version of this
//    func perry() -> Exercise {
//        let work = RepsSet(reps: RepRange(6)!, restSecs: 30)!   // TODO: ideally woulf use no rest
//        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])  // TODO: want to do up to six sets
//        let modality = Modality(Apparatus.bodyWeight, sets)
//        return Exercise("Complex", "Perry Complex", modality, overridePercent: "Squat, Lunge, Row, Curl&Press")
//    }

    // Lower
    // progression: https://old.reddit.com/r/bodyweightfitness/wiki/exercises/squat
    func splitSquats() -> Exercise {
        let warmup = RepsSet(reps: RepRange(8)!, percent: WeightPercent(0.0)!, restSecs: 60)!
        let work = RepsSet(reps: RepRange(min: 4, max: 8)!, restSecs: 120)!
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 9.0))
    }

    func lunge() -> Exercise {
        let warmup = RepsSet(reps: RepRange(4)!, percent: WeightPercent(0.0)!, restSecs: 60)!
        let work = RepsSet(reps: RepRange(min: 4, max: 8)!, restSecs: 120)!
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lunge", "Dumbbell Lunge", modality, Expected(weight: 9.0))
    }

    // Upper
    func planks() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 40, restSecs: 90)!,
            DurationSet(secs: 40, restSecs: 90)!,
            DurationSet(secs: 40, restSecs: 90)!]
        let sets = Sets.durations(durations, targetSecs: [2*60, 2*60, 2*60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Front Plank", "Front Plank", modality)
    }
    
    func pikePushup() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12)!, restSecs: 120)!
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Pike Pushup", "Pike Pushup", modality)
    }

    func reversePlank() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 90)!,
            DurationSet(secs: 50, restSecs: 90)!,
            DurationSet(secs: 50, restSecs: 90)!]
        let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Reverse Plank", "Reverse Plank", modality)
    }
    
    func tricepPress() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12)!, restSecs: 90)!
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Triceps Press", "Standing Triceps Press", modality)
    }

    func latRaise() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12)!, restSecs: 90)!
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lateral Raise", "Side Lateral Raise", modality)
    }

//    let cardio = createWorkout("Cardio", [squats1(), squats2(), squats3(), squats4()], day: nil).unwrap()
    let rehab = createWorkout("Rehab", [shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
    let mobility = createWorkout("Mobility", [formRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
//    let complex = createWorkout("Complex", [perry()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
    let lower = createWorkout("Lower", [splitSquats(), lunge()], days: [.tuesday, .thursday, .saturday]).unwrap()
    let upper = createWorkout("Upper", [planks(), pikePushup(), reversePlank(), tricepPress(), latRaise()], days: [.friday, .sunday]).unwrap()

    let workouts = [rehab, mobility, lower, upper]
    return Program("Home", workouts)
}

var program = home()
var history = History()
