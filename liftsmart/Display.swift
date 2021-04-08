//  Created by Jesse Jones on 3/13/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation
import struct SwiftUI.Color // note that, in general, Display should not depend on view stuff
import class SwiftUI.UIApplication

func newExerciseName(_ workout: Workout, _ name: String) -> String {
    let count = workout.exercises.count({$0.name.starts(with: name)})
    if count == 0 {
        return name
    } else {
        return "\(name)\(count + 1)"
    }
}

/// Views use Action to make model changes. Note that these actions blindly do the
/// change: callers are responsible for verifying that the action should actually
/// be done.
enum Action {
    // Edit screens use transactions to allow model changes to be cancelled.
    case BeginTransaction(name: String)     
    case RollbackTransaction(name: String)  // cancel
    case ConfirmTransaction(name: String)   // ok
    
    // Exercise
    case AdvanceCurrent(Exercise)
    case AppendCurrent(Exercise, String, String)
    case CopyExercise(Exercise)
    case ResetCurrent(Exercise)
    case SetApparatus(Exercise, Apparatus)
    case SetCompleted(Exercise, [Int])
    case SetExerciseName(Workout, Exercise, String)
    case SetExerciseFormalName(Exercise, String)
    case SetExpectedReps(Exercise, [Int])
    case SetExpectedWeight(Exercise, Double)
    case SetSets(Exercise, Sets)
    case ToggleEnableExercise(Exercise)
    case ValidateDurations(String, String, String)  // durations, target, rest
    case ValidateFixedReps(String, String)          // reps, rest
    case ValidateFormalName(String)
    case ValidateMaxReps(String)
    case ValidateMaxRepsTarget(String)
    case ValidateRepRanges(String, String, String, String?) // reps, percent, rest, expected

    // History
    case AppendHistory(Workout, Exercise)
    case DeleteAllHistory(Workout, Exercise)
    case DeleteHistory(Workout, Exercise, History.Record)
    case SetHistoryNote(History.Record, String)
    case SetHistoryWeight(History.Record, Double)

    // Misc
    case SetUserNote(String, String?)    // formalName, note
    case TimePassed
    case ValidateWeight(String, String)

    // Program
    case AddWorkout(String)
    case DelWorkout(Workout)
    case EnableWorkout(Workout, Bool)
    case MoveWorkout(Workout, Int)
    case SetProgramName(String)
    case ValidateProgramName(String)
    case ValidateWorkoutName(String)
    
    // Workout
    case AddExercise(Workout, Exercise)
    case DelExercise(Workout, Exercise)
    case MoveExercise(Workout, Exercise, Int)
    case PasteExercise(Workout)
    case SetWorkoutName(Workout, String)
    case ToggleWorkoutDay(Workout, WeekDay)
    case ValidateExerciseName(Workout, String)
}

/// This is Redux style where Display is serving as the Store object which mediates
/// between views and the model. 
class Display: ObservableObject {
    private(set) var program: Program
    private(set) var history: History
    private(set) var exerciseClipboard: Exercise? = nil
    @Published private(set) var edited = ""         // above should be published but that doesn't work well with classes so we use this lame string to publish chaanges
    @Published private(set) var errMesg = ""        // set when an Action cannot be performed
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
            return !self.errMesg.isEmpty
        }
    }

    /// This is the only way that the model changes.
    func send(_ action: Action, updateUI: Bool = true) {
        func checkExerciseName(_ workout: Workout, _ name: String) -> String? {
            // If this changes PasteExercise may have to change as well.
            if name.isBlankOrEmpty() {
                return "Exercise name cannot be empty"
            } else if workout.exercises.any({$0.name == name}) {
                return "There is already an exercise with that name in the workout"
            }
            return nil
        }

        func checkFormalName(_ name: String) -> String? {
            // We'll allow blank and empty names.
            if name.isBlankOrEmpty() {
                return nil
            } else if (userNotes[name] ?? defaultNotes[name]) == nil {
                return "There is no note for that formal name"
            }
            return nil
        }

        func checkWorkoutName(_ name: String) -> String? {
            if name.isBlankOrEmpty() {
                return "Workout name cannot be empty"
            } else if (self.program.workouts.any({$0.name == name})) {
                return "There is already a workout with that name"
            }
            return nil
        }

        func checkProgramName(_ name: String) -> String? {
            if name.isBlankOrEmpty() {
                return "Program name cannot be empty"
            }
            return nil
        }
        
        func checkWeight(_ text: String) -> String? {
            if let weight = Double(text) {
                if weight < 0.0 {
                    return "Weight cannot be negative (found \(weight))"
                } else {
                   return nil
                }
            } else {
                return "Expected a floating point number for weight (found '\(text)')"
            }
        }

        func checkDurationsSets(_ durationsStr: String, _ targetStr: String, _ restStr: String) -> String? {
            // Note that we don't use comma separated lists because that's more visual noise and
            // because some locales use commas for the decimal points.
            switch coalesce(parseTimes(durationsStr, label: "durations"), parseTimes(targetStr, label: "target"), parseTimes(restStr, label: "rest", zeroOK: true)) {
            case .right((let durations, let target, let rest)):
                let count1 = durations.count
                let count2 = rest.count
                let count3 = target.count
                let match = count1 == count2 && (count3 == 0 || count1 == count3)

                if !match {
                    return "Durations, target, and rest must have the same number of sets (although target can be empty)"
                } else if count1 == 0 {
                    return "Durations and rest need at least one set"
                }
                return nil
            case .left(let err):
                return err
            }
        }
        
        func checkFixedReps(_ repsStr: String, _ restStr: String) -> String? {
            switch coalesce(parseRepRanges(repsStr, label: "reps"), parseTimes(restStr, label: "rest", zeroOK: true)) {
            case .right((let reps, let rest)):
                if reps.count != rest.count {
                    return "Reps and rest counts must match"
                } else if reps.count == 0 {
                    return "Reps and rest need at least one set"
                }
                return nil
            case .left(let err):
                return err
            }
        }

        func checkMaxReps(_ repsStr: String) -> String? {
            switch parseOptionalRep(repsStr, label: "reps") {
            case .right(_):
                return nil
            case .left(let err):
                return err
            }
        }
        
        func checkMaxRepsTarget(_ targetStr: String) -> String? {
            switch parseOptionalRep(targetStr, label: "target") {
            case .right(_):
                return nil
            case .left(let err):
                return err
            }
        }

        func checkRepRanges(_ repsStr: String, _ percentStr: String, _ restStr: String, _ inExpectedStr: String?) -> String? {
            if let expectedStr = inExpectedStr {
                switch coalesce(parseRepRanges(repsStr, label: "reps"),
                                parsePercents(percentStr, label: "percents"),
                                parseTimes(restStr, label: "rest", zeroOK: true),
                                parseReps(expectedStr, label: "expected", emptyOK: true)) {
                case .right((let reps, let percent, let rest, let expected)):
                    let count1 = reps.count
                    let count2 = percent.count
                    let count3 = rest.count
                    let count4 = expected.count
                    let match = count1 == count2 && count1 == count3 && (count4 == 0 || count1 == count4)

                    if !match {
                        return "Number of sets must all match (although expected can be empty)"
                    } else if count1 == 0 {
                        return "Need at least one work set"
                    }
                    return nil
                case .left(let err):
                    return err
                }

            } else {
                switch coalesce(parseRepRanges(repsStr, label: "reps"),
                                parsePercents(percentStr, label: "percents"),
                                parseTimes(restStr, label: "rest", zeroOK: true)) {
                case .right((let reps, let percent, let rest)):
                    let count1 = reps.count
                    let count2 = percent.count
                    let count3 = rest.count
                    let match = count1 == count2 && count1 == count3

                    if !match {
                        return "Number of sets must all match"
                    }
                    return nil
                case .left(let err):
                    return err
                }
            }
        }

        func update() {
            if updateUI {
                self.edited = self.edited.isEmpty ? "\u{200B}" : ""     // toggle between zero-width space and empty
//                self.edited += "\u{200B}"
            }
        }
        
        func saveState() {
            let app = UIApplication.shared.delegate as! AppDelegate
            app.storeObject(self.program, to: "program11")
            app.storeObject(self.history, to: "history")
        }
        
        let errors = self.transactions.last?.errors
        
        switch action {
        // Edit Screens
        case .BeginTransaction(let name):
            // Typically BeginTransaction is called from a View.init method which causes some
            // weirdness:
            // 1) We have to be careful not to trigger a publish because it will lock up the UI.
            // 2) init methods are called many more times than you might naively expect so we
            // can't simply push and pop them,
            if !self.transactions.contains(where: {$0.name == name}) {
                self.transactions.append(Transaction(name: name, program: self.program.clone()))
            }
            return
        case .RollbackTransaction(let name):
            assert(name == self.transactions.last!.name)
            self.program = self.transactions.popLast()!.program
        case .ConfirmTransaction(let name):
            assert(name == self.transactions.last!.name)
            assert(!errors!.hasError)
            let _ = self.transactions.popLast()
            saveState()

        // Exercise
        case .AdvanceCurrent(let exercise):
            exercise.current!.setIndex += 1
            update()
        case .AppendCurrent(let exercise, let reps, let weight):
            exercise.current!.actualReps.append(reps)
            exercise.current!.actualWeights.append(weight)
            exercise.current!.setIndex += 1
            update()
        case .CopyExercise(let exercise):
            exerciseClipboard = exercise
        case .ResetCurrent(let exercise):
            let current = Current(weight: exercise.expected.weight)
            exercise.current = current
            update()
        case .SetApparatus(let exercise, let apparatus):
            exercise.modality.apparatus = apparatus
            update()
        case .SetCompleted(let exercise, let completed):
            exercise.current!.completed = completed
            update()
        case .SetExerciseName(let workout, let exercise, let name):
            assert(checkExerciseName(workout, name) == nil)
            exercise.name = name
            update()
        case .SetExerciseFormalName(let exercise, let name):
            assert(checkFormalName(name) == nil)
            exercise.formalName = name
            update()
        case .SetExpectedReps(let exercise, let reps):
            exercise.expected.reps = reps
            update()
        case .SetExpectedWeight(let exercise, let weight):
            exercise.expected.weight = weight
            update()
        case .SetSets(let exercise, let sets):
            exercise.modality = Modality(exercise.modality.apparatus, sets)
            update()
        case .ToggleEnableExercise(let exercise):
            exercise.enabled = !exercise.enabled
            update()
        case .ValidateDurations(let durations, let target, let rest):
            if let err = checkDurationsSets(durations, target, rest) {
                errors!.add(key: "set durations sets", error: err)
            } else {
                errors!.reset(key: "set durations sets")
            }
        case .ValidateFixedReps(let reps, let rest):
            if let err = checkFixedReps(reps, rest) {
                errors!.add(key: "set fixed reps sets", error: err)
            } else {
                errors!.reset(key: "set fixed reps sets")
            }
        case .ValidateFormalName(let name):
            if let err = checkFormalName(name) {
                errors!.add(key: "set formal name", warning: err)
            } else {
                errors!.reset(key: "set formal name")
            }
        case .ValidateMaxReps(let reps):
            if let err = checkMaxReps(reps) {
                errors!.add(key: "set max reps sets", error: err)
            } else {
                errors!.reset(key: "set max reps sets")
            }
        case .ValidateMaxRepsTarget(let target):
            if let err = checkMaxRepsTarget(target) {
                errors!.add(key: "set max reps target", error: err)
            } else {
                errors!.reset(key: "set max reps target")
            }
        case .ValidateRepRanges(let reps, let percent, let rest, let expected):
            if let err = checkRepRanges(reps, percent, rest, expected) {
                errors!.add(key: "set rep ranges", error: err)
            } else {
                errors!.reset(key: "set rep ranges")
            }

        // History
        case .AppendHistory(let workout, let exercise):
            self.history.append(workout, exercise)
            saveState()
            update()
        case .DeleteAllHistory(let workout, let exercise):
            self.history.deleteAll(workout, exercise)
            update()
        case .DeleteHistory(let workout, let exercise, let record):
            self.history.delete(workout, exercise, record)
            update()
        case .SetHistoryNote(let record, let text):
            record.note = text
            update()
        case .SetHistoryWeight(let record, let weight):
            record.weight = weight
            update()

        // Misc
        case .SetUserNote(let formalName, let note):
            userNotes[formalName] = note
            update()
        case .TimePassed:
            // Enough time has passed that UIs should be refreshed.
            update()

        case .ValidateWeight(let weight, let subtype):
            if let err = checkWeight(weight) {
                errors!.add(key: "set \(subtype)", error: err)
            } else {
                errors!.reset(key: "set \(subtype)")
            }

        // Program
        case .AddWorkout(let name):
            assert(checkWorkoutName(name) == nil)
            let workout = Workout(name, [], days: [])
            self.program.workouts.append(workout)
            update()
        case .DelWorkout(let workout):
            let index = self.program.workouts.firstIndex(where: {$0 === workout})!
            self.program.workouts.remove(at: index)
            update()
        case .EnableWorkout(let workout, let enable):
            workout.enabled = enable
            update()
        case .MoveWorkout(let workout, let by):
            assert(by != 0)
            let index = self.program.workouts.firstIndex(where: {$0 === workout})!
            let _ = self.program.workouts.remove(at: index)
            self.program.workouts.insert(workout, at: index + by)
            update()
        case .SetProgramName(let name):
            assert(checkProgramName(name) == nil)
            self.program.name = name
            update()
        case .ValidateProgramName(let name):
            if let err = checkProgramName(name) {
                errors!.add(key: "add program", error: err)
            } else {
                errors!.reset(key: "add program")
            }
        case .ValidateWorkoutName(let name):
            if let err = checkWorkoutName(name) {
                errors!.add(key: "add workout", error: err)
            } else {
                errors!.reset(key: "add workout")
            }

        // Workout
        case .AddExercise(let workout, let exercise):
            workout.exercises.append(exercise)
            update()
        case .DelExercise(let workout, let exercise):
            let index = workout.exercises.firstIndex(where: {$0 === exercise})!
            workout.exercises.remove(at: index)
            update()
        case .MoveExercise(let workout, let exercise, let by):
            let index = workout.exercises.firstIndex(where: {$0 === exercise})!
            workout.moveExercise(index, by: by)
            update()
        case .PasteExercise(let workout):
            let exercise = self.exerciseClipboard!.clone()     // clone so pasting twice doesn't add the same exercise
            exercise.name = newExerciseName(workout, self.exerciseClipboard!.name)
            workout.exercises.append(exercise)
            update()
        case .SetWorkoutName(let workout, let name):
            assert(checkWorkoutName(name) == nil);
            workout.name = name
            update()
        case .ToggleWorkoutDay(let workout, let day):
            workout.days[day.rawValue] = !workout.days[day.rawValue]
            update()
        case .ValidateExerciseName(let workout, let name):
            if let err = checkExerciseName(workout, name) {
                errors!.add(key: "add exercise", error: err)
            } else {
                errors!.reset(key: "add exercise")
            }
        }

        let (err, color) = self.transactions.last?.errors.getError() ?? ("", .black)
        if err != self.errMesg || color != self.errColor {
            self.errMesg = err
            self.errColor = color
        }
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
                return !errors.isEmpty
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
