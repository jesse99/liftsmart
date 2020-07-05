//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

var nextID: Int = 0

/// An Exercise all the details for how to do a particular movement. It does not
/// include history or achievement information.
class Exercise: Hashable, Identifiable, Storable {
    var name: String             // "Heavy Bench"
    var formalName: String       // "Bench Press"
    var modality: Modality
    var expected: Expected
    var current: Current? = nil // this is reset to nil if it's been too long since the user was doing the exercise
    let id: Int                 // used for hashing

    init(_ name: String, _ formalName: String, _ modality: Modality, _ expected: Expected = Expected(weight: 0.0)) {
        self.name = name
        self.formalName = formalName
        self.modality = modality
        self.expected = expected
        self.id = nextID
        nextID += 1
    }
        
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.formalName = store.getStr("formalName")
        self.modality = store.getObj("modality")
        self.expected = store.getObj("expected")
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
        store.addStr("formalName", formalName)
        store.addObj("modality", modality)
        store.addObj("expected", expected)
        if let c = self.current {
            store.addObj("current", c)
        }
        store.addInt("id", id)
    }

    func shouldReset(numSets: Int) -> Bool {
        if let current = self.current {
            // If it's been a long time since the user began the exercise then
            // start over. If the user has finished the exercise then give them
            // the option to do it again.
            return Date().hoursSinceDate(current.startDate) > window || current.setIndex >= numSets
        } else {
            return true
        }
    }
        
    func initCurrent(numSets: Int) {
        if let current = self.current {
            // If it's been a long time since the user began the exercise then
            // start over. If the user has finished the exercise then give them
            // the option to do it again.
            if Date().hoursSinceDate(current.startDate) > window || current.setIndex >= numSets {
                self.current = Current(weight: self.expected.weight)
            }
        } else {
            self.current = Current(weight: self.expected.weight)
        }
    }
        
    func inProgress(_ workout: Workout, _ history: History) -> Bool {
        if let current = self.current {
            return Date().hoursSinceDate(current.startDate) < window && current.setIndex > 0 && !recentlyCompleted(workout, history)
        } else {
            return false
        }
    }
        
    func recentlyCompleted(_ workout: Workout, _ history: History) -> Bool {
        if let completed = history.lastCompleted(workout, self) {
            return Date().hoursSinceDate(completed) < window
        } else {
            return false
        }
    }
        
    func dateCompleted(_ workout: Workout, _ history: History) -> Date? {
        if let latest = history.lastCompleted(workout, self) {
            return latest
        } else {
            return nil
        }
    }
    
    static func ==(lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    private let window:Double = 2.0
}
