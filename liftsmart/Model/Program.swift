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
class Program: CustomDebugStringConvertible, Sequence, Storable {
    var name: String

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

    var count: Int {
        get {return workouts.count}
    }
    
    subscript(_ index: Int) -> Workout {
        return self.workouts[index]
    }
    
    func addWorkout(_ name: String) -> String? {
        if self.workouts.first(where: {$0.name == name}) != nil {
            return "There is already a workout named '\(name)'."
        }
        
        switch createWorkout(name, [], day: nil) {
        case .left(let err):
            return err
        case .right(let workout):
            self.workouts.append(workout)
            return nil
        }
    }
    
    func delete(_ index: Int) {
        self.workouts.remove(at: index)
    }

    func makeIterator() -> Program.Iterator {
        return Program.Iterator(program: self)
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
    
    struct Iterator: IteratorProtocol {
        let program: Program
        var index: Int = 0
        
        mutating func next() -> Workout? {
            if self.index < self.program.count {
                let result = self.program[self.index]
                self.index += 1
                return result
            } else {
                return nil
            }
        }
    }

    private var workouts: [Workout] // TODO: workout names must be unique (because of Identifiable)
    private var notes: [EditNote]
}
