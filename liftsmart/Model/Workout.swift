//  Created by Jesse Vorisek on 5/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

enum WeekDay: Int {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
}

func createWorkout(_ name: String, _ exercises: [Exercise], days: [WeekDay]) -> Either<String, Workout> {
    if name.isEmpty {return .left("Workout name cannot be empty")}
    let names = exercises.map {(e) -> String in e.name}
    if names.count != Set(names).count {return .left("Exercise names must be unique")}

    return .right(Workout(name, exercises, days: days))
}

func createWorkout(_ name: String, _ exercises: [Exercise], day: WeekDay?) -> Either<String, Workout> {
   return createWorkout(name, exercises, days: day != nil ? [day!] : [])
}

class Workout: CustomDebugStringConvertible, Identifiable, Storable {
    var name: String
    var enabled: Bool           // true if the user wants to perform this workout
    var exercises: [Exercise]   // exercise names don't have to be unique
    var days: [Bool]            // indices are Sun, Mon, ..., Sat, true means workout is scheduled for that day, all false means can do the workout any day

    fileprivate init(_ name: String, _ exercises: [Exercise], days: [WeekDay]) {
        self.name = name
        self.enabled = true
        self.exercises = exercises
        self.days = Array(repeating: false, count: 7)
        for d in days {
            self.days[d.rawValue] = true
        }
    }
    
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.enabled = store.getBool("enabled", ifMissing: true)
        self.exercises = store.getObjArray("exercises")
        self.days = store.getBoolArray("days", ifMissing: [])
    }
    
    func save(_ store: Store) {
        store.addStr("name", name)
        store.addBool("enabled", enabled)
        store.addObjArray("exercises", exercises)
        store.addBoolArray("days", days)
    }
    
    func clone() -> Workout {
        let store = Store()
        store.addObj("self", self)
        let result: Workout = store.getObj("self")
        return result
    }
        
    func restore(_ original: Workout) {
        self.name = original.name
        self.enabled = original.enabled
        self.exercises = original.exercises
        self.days = original.days
    }

    func addExercise(_ name: String) {
        let durations = createDurationSets(secs: [60], rest: [60])
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        let exercise = Exercise(name, "", modality)
        self.exercises.append(exercise)
    }
    
    func moveExercise(_ index: Int, by: Int) {
        assert(by != 0)
        let exercise = self.exercises.remove(at: index)
        self.exercises.insert(exercise, at: index + by)
    }

    // Partial is true if not all exercises were completed on that date.
    func dateCompleted(_ history: History) -> (date: Date, partial: Bool)? {
        func lastCompleted() -> Date? {
            var date: Date? = nil
            for exercise in self.exercises {
                if let candidate = exercise.dateCompleted(self, history) {
                    if date == nil || candidate.compare(date!) == .orderedDescending {
                        date = candidate
                    }
                }
            }
            return date
        }
        
        let date: Date? = lastCompleted()
        var partial = false

        if let latest = date {
            for exercise in self.exercises {
                let calendar = Calendar.current
                if let completed = exercise.dateCompleted(self, history) {
                    if !calendar.isDate(completed, inSameDayAs: latest) {   // this won't be exactly right if anyone is crazy enough to do workouts at midnight
                        partial = true
                    }
                } else {
                    partial = true
                }
            }
        }

        return date != nil ? (date!, partial) : nil
    }
    
    var debugDescription: String {
        get {
            return self.name
        }
    }

    var id: String {
        get {
            return self.name
        }
    }
}

