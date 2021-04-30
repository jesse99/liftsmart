//  Created by Jesse Vorisek on 5/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

struct EditNote: CustomDebugStringConvertible, Storable {
    let date: Date
    let note: String

    init(_ note: String) {
        self.date = Date()
        self.note = note
    }
        
    init(from store: Store) {
        self.date = store.getDate("date")
        self.note = store.getStr("note")
    }
    
    func save(_ store: Store) {
        store.addDate("date", date)
        store.addStr("note", note)
    }

    var debugDescription: String {
        get {
            return self.note
        }
    }
}

/// This is the top-level type representing everything that the user is expected to do within a period of time.
/// For example, three workouts each week.
class Program: CustomDebugStringConvertible, Storable {
    var name: String
    var workouts: [Workout]
    var notes: [EditNote]
    var blockStart: Date?

    init(_ name: String, _ workouts: [Workout]) {
        self.name = name
        self.workouts = workouts
        self.notes = []
        self.blockStart = nil
        
        self.addNote("Created")
    }
        
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.workouts = store.getObjArray("workouts")
        self.notes = store.getObjArray("notes")
        if store.hasKey("blockStart") {
            self.blockStart = store.getDate("blockStart")
        } else {
            self.blockStart = nil
        }
    }
    
    func save(_ store: Store) {
        store.addStr("name", name)
        store.addObjArray("workouts", workouts)
        store.addObjArray("notes", notes)
        if let date = blockStart {
            store.addDate("blockStart", date)
        }
    }
    
    func clone() -> Program {
        let store = Store()
        store.addObj("self", self)
        let result: Program = store.getObj("self")
        return result
    }
    
    // Largest week number in workouts.
    func numWeeks() -> Int? {
        if let workout = workouts.max(by: {($0.weeks.max() ?? 0) < ($1.weeks.max() ?? 0)}) {
            return workout.weeks.max()
        }
        return nil
    }

    /// A note has to be added after significant changes. This makes it possible for users and advisors
    /// to evaluate the effect of changes on performance.
    func addNote(_ text: String) {
        notes.append(EditNote(text))
    }
    
    var debugDescription: String {
        get {
            return self.name
        }
    }
}

func home() -> Program {
    // https://www.defrancostraining.com/joe-ds-qlimber-11q-flexibility-routine/
    func formRolling() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Foam Rolling", "IT-Band Foam Roll", modality)
    }

    func ironCross() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Bent-knee Iron Cross", "Bent-knee Iron Cross", modality)
    }

    func vSit() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Roll-over into V-sit", "Roll-over into V-sit", modality)
    }

    func frog() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Rocking Frog Stretch", "Rocking Frog Stretch", modality)
    }

    func fireHydrant() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Fire Hydrant Hip Circle", "Fire Hydrant Hip Circle", modality)
    }

    func mountain() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 30)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Mountain Climber", "Mountain Climber", modality)
    }

    func cossack() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Cossack Squat", "Cossack Squat", modality, Expected(weight: 0.0, reps: [8]))
    }

    func piriformis() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 30, restSecs: 0), DurationSet(secs: 30, restSecs: 0)])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Piriformis Stretch", "Seated Piriformis Stretch", modality)
    }
    
    // Rehab
    func shoulderFlexion() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(12), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Shoulder Flexion", "Single Shoulder Flexion", modality)
    }
    
    func bicepsStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 15, restSecs: 30),
            DurationSet(secs: 15, restSecs: 30),
            DurationSet(secs: 15, restSecs: 0)]
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Biceps Stretch", "Wall Biceps Stretch", modality)
    }
    
    func externalRotation() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("External Rotation", "Lying External Rotation", modality)
    }
    
    func sleeperStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 30, restSecs: 30),
            DurationSet(secs: 30, restSecs: 30),
            DurationSet(secs: 30, restSecs: 0)]
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
        let warmup = RepsSet(reps: RepRange(min: 4, max: 4), percent: WeightPercent(0.0), restSecs: 90)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60)
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }

    func lunge() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 150)
        let work2 = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 0)
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work2], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lunge", "Dumbbell Lunge", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }

    // Upper
    func planks() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 2*60),
            DurationSet(secs: 50, restSecs: 2*60),
            DurationSet(secs: 50, restSecs: 2*60)]
        let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Front Plank", "Front Plank", modality)
    }
    
    func pushup() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 150)
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Pushup", "Pushup", modality, Expected(weight: 0.0, reps: [10, 10, 10]))
    }

    func reversePlank() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 90),
            DurationSet(secs: 50, restSecs: 90),
            DurationSet(secs: 50, restSecs: 90)]
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
        let work = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 120)
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lateral Raise", "Side Lateral Raise", modality, Expected(weight: 8.2, reps: [12, 12, 12]))
    }

    func tricepPress() -> Exercise {
        let work1 = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 120)
        let work2 = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 0)
        let sets = Sets.repRanges(warmups: [], worksets: [work1, work1, work2], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Triceps Press", "Standing Triceps Press", modality, Expected(weight: 8.2, reps: [11, 11, 11]))
    }

//    let cardio = createWorkout("Cardio", [squats1(), squats2(), squats3(), squats4()], day: nil).unwrap()
    let rehab = createWorkout("Rehab", [shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
    let mobility = createWorkout("Mobility", [formRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
//    let complex = createWorkout("Complex", [perry()], days: [.saturday, .sunday, .tuesday, .thursday, .friday]).unwrap()
    let lower = createWorkout("Lower", [splitSquats(), lunge()], days: [.tuesday, .thursday, .saturday]).unwrap()
    let upper = createWorkout("Upper", [planks(), pushup(), reversePlank(), curls(), latRaise(), tricepPress()], days: [.friday, .sunday]).unwrap()

    let workouts = [rehab, mobility, lower, upper]
    return Program("Home", workouts)
}

func defaultProgram(_ name: String) -> Program {
    return Program(name, [])
}
