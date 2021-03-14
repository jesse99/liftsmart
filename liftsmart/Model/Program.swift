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

    init(_ name: String, _ workouts: [Workout]) {
        self.name = name
        self.workouts = workouts
        self.notes = []
        
        self.addNote("Created")
    }
        
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.workouts = store.getObjArray("workouts")
        self.notes = store.getObjArray("notes")
    }
    
    func save(_ store: Store) {
        store.addStr("name", name)
        store.addObjArray("workouts", workouts)
        store.addObjArray("notes", notes)
    }
    
    func clone() -> Program {
        let store = Store()
        store.addObj("self", self)
        let result: Program = store.getObj("self")
        return result
    }
        
    func restore(_ original: Program) {
        self.name = original.name
        self.workouts = original.workouts
        self.notes = original.notes
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
