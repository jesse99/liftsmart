//  Created by Jesse Vorisek on 5/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

struct EditNote: CustomDebugStringConvertible {
    let date: Date
    let note: String

    init(_ note: String) {
        self.date = Date()
        self.note = note
    }
    
    var debugDescription: String {
        get {
            return self.note
        }
    }
}

/// This is the top-level type representing everything that the user is expected to do within a period of time.
/// For example, three workouts each week.
class Program: CustomDebugStringConvertible, Sequence {
    var name: String

    init(_ name: String, _ workouts: [Workout]) {
        self.name = name
        self.workouts = workouts
        self.notes = []
        
        self.addNote("Created")
    }
        
    var count: Int {
        get {return workouts.count}
    }
    
    subscript(_ index: Int) -> Workout {
        return self.workouts[index]
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
