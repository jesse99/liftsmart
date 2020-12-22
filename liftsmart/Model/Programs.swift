//  Created by Jesse Vorisek on 5/25/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

func createReps(reps: [Int], percent: [Int] = [], rest: [Int]) -> [RepsSet] {
    assert(reps.count == rest.count)
    assert(percent.isEmpty || reps.count == percent.count)
    
    var result: [RepsSet] = []
    for i in 0..<reps.count {
        if percent.isEmpty {
            result.append(RepsSet.create(reps: RepRange.create(reps[i]).unwrap(), restSecs: rest[i]).unwrap())
        } else {
            result.append(RepsSet.create(reps: RepRange.create(reps[i]).unwrap(), percent: WeightPercent.create(Double(percent[i])/100.0).unwrap(), restSecs: rest[i]).unwrap())
        }
    }
    return result
}

func createReps(reps: [ClosedRange<Int>], percent: [Int] = [], rest: [Int]) -> [RepsSet] {
    assert(reps.count == rest.count)
    
    var result: [RepsSet] = []
    for i in 0..<reps.count {
        if percent.isEmpty {
            result.append(RepsSet.create(reps: RepRange.create(min: reps[i].lowerBound, max: reps[i].upperBound).unwrap(), restSecs: rest[i]).unwrap())
        } else {
            result.append(RepsSet.create(reps: RepRange.create(min: reps[i].lowerBound, max: reps[i].upperBound).unwrap(), percent: WeightPercent.create(Double(percent[i])/100.0).unwrap(), restSecs: rest[i]).unwrap())

        }
    }
    return result
}

func createDurations(secs: [Int], rest: [Int]) -> [DurationSet] {
    assert(secs.count == rest.count)
    
    var result: [DurationSet] = []
    for i in 0..<secs.count {
        result.append(DurationSet.create(secs: secs[i], restSecs: rest[i]).unwrap())
    }
    return result
}

func home() -> Program {
    // https://www.defrancostraining.com/joe-ds-qlimber-11q-flexibility-routine/
    func formRolling() -> Exercise {
        let work = createReps(reps: [15], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Foam Rolling", "IT-Band Foam Roll", modality)
    }

    func ironCross() -> Exercise {
        let work = createReps(reps: [10], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Bent-knee Iron Cross", "Bent-knee Iron Cross", modality)
    }

    func vSit() -> Exercise {
        let work = createReps(reps: [15], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Roll-over into V-sit", "Roll-over into V-sit", modality)
    }

    func frog() -> Exercise {
        let work = createReps(reps: [10], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Rocking Frog Stretch", "Rocking Frog Stretch", modality)
    }

    func fireHydrant() -> Exercise {
        let work = createReps(reps: [10], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Fire Hydrant Hip Circle", "Fire Hydrant Hip Circle", modality)
    }

    func mountain() -> Exercise {
        let work = createReps(reps: [10], rest: [30])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Mountain Climber", "Mountain Climber", modality)
    }

    func cossack() -> Exercise {
        let work = createReps(reps: [10], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Cossack Squat", "Cossack Squat", modality, Expected(weight: 0.0, reps: [8]))
    }

    func piriformis() -> Exercise {
        let durations = createDurations(secs: [30, 30], rest: [0, 0])
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Piriformis Stretch", "Seated Piriformis Stretch", modality)
    }
    
    // Rehab
    func shoulderFlexion() -> Exercise {
        let work = createReps(reps: [8...12], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Shoulder Flexion", "Single Shoulder Flexion", modality)
    }
    
    func bicepsStretch() -> Exercise {
        let durations = createDurations(secs: [15, 15, 15], rest: [30, 30, 0])
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Biceps Stretch", "Wall Biceps Stretch", modality)
    }
    
    func externalRotation() -> Exercise {
        let work = createReps(reps: [15], rest: [0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("External Rotation", "Lying External Rotation", modality)
    }
    
    func sleeperStretch() -> Exercise {
        let durations = createDurations(secs: [30, 30, 30], rest: [30, 30, 0])
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
        let warmup = createReps(reps: [4], percent: [0], rest: [90])
        let work = createReps(reps: [4...8, 4...8, 4...8], rest: [3*60, 3*60, 3*60])
        let sets = Sets.repRanges(warmups: warmup, worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }

    func lunge() -> Exercise {
        let work = createReps(reps: [4...8, 4...8, 4...8], rest: [150, 150, 0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lunge", "Dumbbell Lunge", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }

    // Upper
    func planks() -> Exercise { // TODO: this should be some sort of progression
        let durations = createDurations(secs: [45, 45, 45], rest: [90, 90, 90])
        let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Front Plank", "Front Plank", modality)
    }
    
    func pikePushup() -> Exercise {
        let work = createReps(reps: [4...12, 4...12, 4...12], rest: [150, 150, 150])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Pike Pushup", "Pike Pushup", modality, Expected(weight: 0.0, reps: [7, 7, 7]))
    }

    func reversePlank() -> Exercise { // TODO: this should be some sort of progression
        let durations = createDurations(secs: [50, 50, 50], rest: [90, 90, 90])
        let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Reverse Plank", "Reverse Plank", modality)
    }
    
    func curls() -> Exercise {
        let sets = Sets.maxReps(restSecs: [90, 90, 90])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Curls", "Hammer Curls", modality, Expected(weight: 16.4, reps: [30]))
     }

    func latRaise() -> Exercise {
        let work = createReps(reps: [4...12, 4...12, 4...12], rest: [120, 120, 120])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lateral Raise", "Side Lateral Raise", modality, Expected(weight: 8.2, reps: [12, 12, 12]))
    }

    func tricepPress() -> Exercise {
        let work = createReps(reps: [4...12, 4...12, 4...12], rest: [120, 120, 0])
        let sets = Sets.repRanges(warmups: [], worksets: work, backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Triceps Press", "Standing Triceps Press", modality, Expected(weight: 8.2, reps: [11, 11, 11]))
    }

//    let cardio = createWorkout("Cardio", [squats1(), squats2(), squats3(), squats4()], day: nil).unwrap()
    let rehab = createWorkout("Rehab", [shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
    let mobility = createWorkout("Mobility", [formRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
//    let complex = createWorkout("Complex", [perry()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
    let lower = createWorkout("Lower", [splitSquats(), lunge()], days: [.tuesday, .thursday, .saturday]).unwrap()
    let upper = createWorkout("Upper", [planks(), pikePushup(), reversePlank(), curls(), latRaise(), tricepPress()], days: [.friday, .sunday]).unwrap()

    let workouts = [rehab, mobility, lower, upper]
    return Program("Home", workouts)
}

var program = home()
var history = History()
