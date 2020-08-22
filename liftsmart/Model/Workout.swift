//  Created by Jesse Vorisek on 5/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

enum WeekDay: Int {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
}

class Workout: CustomDebugStringConvertible, Identifiable, Storable {
    var name: String
    var exercises: [Exercise]
    var days: [Bool]            // indices are Sun, Mon, ..., Sat, true means workout is scheduled for that day, all false means can do the workout any day

    init?(_ name: String, _ exercises: [Exercise], day: WeekDay?) {
        if name.isEmpty {return nil}
        let names = exercises.map {(e) -> String in e.name}
        if names.count != Set(names).count {return nil}     // exercise names must be unique

        self.name = name
        self.exercises = exercises
        self.days = Array(repeating: false, count: 7)
        if let d = day {
            self.days[d.rawValue] = true
        }
    }
    
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.exercises = store.getObjArray("exercises")
        self.days = store.getBoolArray("days", ifMissing: [])
    }
    
    func save(_ store: Store) {
        store.addStr("name", name)
        store.addObjArray("exercises", exercises)
        store.addBoolArray("days", days)
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
