//  Created by Jesse Jones on 3/13/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation
import struct SwiftUI.Color // note that, in general, Display should not depend on view stuff
import class SwiftUI.UIApplication

/// Views use Action to make model changes.
enum Action {
    // Edit screens use transaction to allow model changes to be cancelled.
    case BeginTransaction(name: String)     // name is used for sanity checking
    case RollbackTransaction(name: String)  // cancel
    case ConfirmTransaction(name: String)   // ok
    
    // Program
    case AddWorkout(String)
    case DelWorkout(String)
    case EnableWorkout(String, Bool)
    case MoveWorkout(String, Int)
    case SetProgramName(String)
}

/// This is Redux style where Display is serving as the Store object which mediates
/// between views and the model. 
class Display: ObservableObject {
    @Published private(set) var program: Program
    @Published private(set) var history: History
    @Published private(set) var errMesg = ""           // set when an Action cannot be performed
    @Published private(set) var errColor = Color.black

    init() {
        let app = UIApplication.shared.delegate as! AppDelegate
        if let store = app.loadStore(from: "program11") {
            self.program = Program(from: store)
        } else {
            self.program = home()
        }
        if let store = app.loadStore(from: "history") {
            self.history = History(from: store)
        } else {
            self.history = History()
        }
    }
    
    // For testing
    init(program: Program, history: History) {
        self.program = program
        self.history = history
    }
    
    var hasError: Bool {
        get {
            return self.transactions.last?.errors.hasError ?? false
        }
    }

    /// This is the only way that the model changes.
    func send(_ action: Action) {
        let errors = self.transactions.last?.errors
        
        switch action {
        // Edit Screens
        case .BeginTransaction(let name):
            self.transactions.append(Transaction(name: name, program: self.program.clone()))
        case .RollbackTransaction(let name):
            assert(name == self.transactions.last!.name)
            self.program = self.transactions.popLast()!.program
        case .ConfirmTransaction(let name):
            assert(name == self.transactions.last!.name)
            assert(!errors!.hasError)
            let _ = self.transactions.popLast()

            let app = UIApplication.shared.delegate as! AppDelegate
            app.storeObject(self.program, to: "program11")
            app.storeObject(self.history, to: "history")

        // Program
        case .AddWorkout(let name):
            if name.isBlankOrEmpty() {
                errors!.add(key: "add workout", error: "Workout name cannot be empty")
            } else if (self.program.workouts.any({$0.name == name})) {
                errors!.add(key: "add workout", error: "There is already a workout with that name")
            } else {
                let workout = Workout(name, [], days: [])
                self.program.workouts.append(workout)
                errors!.reset(key: "add workout")
            }
        case .DelWorkout(let name):
            let index = self.program.workouts.firstIndex(where: {$0.name == name})!
            self.program.workouts.remove(at: index)
        case .EnableWorkout(let name, let enable):
            let workout = self.program.workouts.first(where: {$0.name == name})!
            workout.enabled = enable
        case .MoveWorkout(let name, let by):
            assert(by != 0)
            let index = self.program.workouts.firstIndex(where: {$0.name == name})!
            let workout = self.program.workouts.remove(at: index)
            self.program.workouts.insert(workout, at: index + by)
        case .SetProgramName(let name):
            if name.isBlankOrEmpty() {
                errors!.add(key: "set program name", error: "Program name cannot be empty")
            } else {
                self.program.name = name
                errors!.reset(key: "set program name")
            }
        }
        
        let (err, color) = self.transactions.last?.errors.getError() ?? ("", .black)
        self.errMesg = err
        self.errColor = color
    }

    private struct Transaction {
        let name: String
        let program: Program
        let errors = ActionErrors()
    }
    
    // This is used to avoid losing UI errors as the user switches context. For example if there are A
    // and B text fields and each has validation upon changes then without this class the user could have
    // an error on editing A that is lost if the user switches to B without fixing the problem.
    private class ActionErrors {
        func add(key: String, error inMesg: String) {
            assert(!key.isEmpty)
            assert(!inMesg.isEmpty)
            
            var mesg = inMesg
            if !mesg.hasSuffix(".") {
                mesg += "."
            }
            
            errors[key] = mesg
            warnings[key] = nil
        }
        
        func add(key: String, warning inMesg: String) {
            assert(!key.isEmpty)
            assert(!inMesg.isEmpty)
            
            var mesg = inMesg
            if !mesg.hasSuffix(".") {
                mesg += "."
            }
            
            errors[key] = nil
            warnings[key] = mesg
        }
        
        func reset(key: String) {
            assert(!key.isEmpty)

            errors[key] = nil
            warnings[key] = nil
        }

        var hasError: Bool {
            get {
                return !errors.isEmpty || !warnings.isEmpty
            }
        }

        func getError() -> (String, Color) {
            var result = ""
            
            var keys = errors.keys.sorted() // allows callers some control over which errors are reported first
            for key in keys {
                if !result.isEmpty {
                    result += " "
                }
                result += errors[key]!
            }
            
            keys = warnings.keys.sorted()
            for key in keys {
                if !result.isEmpty {
                    result += " "
                }
                result += warnings[key]!
            }
            
            return (result, !errors.isEmpty ? .red : .orange)
        }

        private var errors: [String: String] = [:]
        private var warnings: [String: String] = [:]
    }

    private var transactions: [Transaction] = []
}
