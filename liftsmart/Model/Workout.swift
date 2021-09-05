//  Created by Jesse Vorisek on 5/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

enum WeekDay: Int {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
}

class ExerciseInstance: Hashable, Identifiable, Storable {
    var name: String             // used to locate the exercise in the program
    var enabled: Bool            // true if the user wants to perform this exercise within this workout
    var current: Current? = nil  // this is reset to nil if it's been too long since the user was doing the exercise
    var id: Int                  // used for hashing

    init(_ name: String) {
        self.name = name
        self.enabled = true
        self.id = nextID
        nextID += 1
    }
        
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.enabled = store.getBool("enabled", ifMissing: true)
        if store.hasKey("current") {
            self.current = store.getObj("current")
        } else {
            self.current = nil
        }
        self.id = store.getInt("id")
        
        if self.id >= nextID {
            nextID = self.id + 1
        }
    }
    
    func save(_ store: Store) {
        store.addStr("name", name)
        store.addBool("enabled", enabled)
        if let c = self.current {
            store.addObj("current", c)
        }
        store.addInt("id", id)
    }
    
    func clone() -> ExerciseInstance {  // TODO: do we need this?
        let store = Store()
        store.addObj("self", self)
        let result: ExerciseInstance = store.getObj("self")
        return result
    }

    func copy() -> ExerciseInstance {
        let result = self.clone()
        result.id = nextID
        nextID += 1
        return result
    }

    static func ==(lhs: ExerciseInstance, rhs: ExerciseInstance) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class Workout: CustomDebugStringConvertible, Identifiable, Storable {
    var name: String
    var enabled: Bool                   // true if the user wants to perform this workout
    var exercises: [ExerciseInstance]   // exercise names don't have to be unique
    var days: [Bool]                    // indices are Sun, Mon, ..., Sat, true means workout is scheduled for that day, all false means can do the workout any day
    var weeks: [Int]                    // empty => every week, otherwise 1-based sorted week indexes

    var oldExercises: [Exercise]        // get rid of this

    init(_ name: String, _ exercises: [String], days: [WeekDay] = [], weeks: [Int] = []) {
        self.name = name
        self.enabled = true
        self.exercises = exercises.map {ExerciseInstance($0)}
        self.days = Array(repeating: false, count: 7)
        for d in days {
            self.days[d.rawValue] = true
        }
        self.weeks = weeks
        self.oldExercises = []
    }
    
    convenience init(_ name: String, _ exercises: [String], day: WeekDay?, weeks: [Int] = []) {
        self.init(name, exercises, days: day != nil ? [day!] : [], weeks: weeks)
    }
    
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.enabled = store.getBool("enabled", ifMissing: true)
        self.days = store.getBoolArray("days", ifMissing: [])
        self.weeks = store.getIntArray("weeks", ifMissing: [])
        
        if store.hasKey("newExercises") {
            self.exercises = store.getObjArray("newExercises")
            self.oldExercises = []

        } else {
            self.oldExercises = store.getObjArray("exercises")
            self.exercises = oldExercises.map {ExerciseInstance($0.name)}
        }
    }
    
    func save(_ store: Store) {
        store.addStr("name", name)
        store.addBool("enabled", enabled)
        store.addObjArray("newExercises", exercises)
        store.addBoolArray("days", days)
        store.addIntArray("weeks", weeks)
    }
    
    func clone() -> Workout {
        let store = Store()
        store.addObj("self", self)
        let result: Workout = store.getObj("self")
        return result
    }
        
    func moveExercise(_ index: Int, by: Int) {
        ASSERT_NE(by, 0)
        let exercise = self.exercises.remove(at: index)
        self.exercises.insert(exercise, at: index + by)
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

