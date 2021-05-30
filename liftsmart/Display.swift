//  Created by Jesse Jones on 3/13/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation
import struct SwiftUI.Color // note that, in general, Display should not depend on view stuff
import class SwiftUI.UIApplication

var overrideNow: Date? = nil

func now() -> Date {
    return overrideNow ?? Date()
}

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
    case AppendCurrent(Exercise, String, Double?)
    case CopyExercise([Exercise])
    case DefaultApparatus(Workout, Exercise, Apparatus) // these two are used to (re)set the exercise to a default value
    case DefaultSets(Workout, Exercise, Sets)
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
    case ValidateExpectedRepList(String)
    case ValidateFixedReps(String, String)          // reps, rest
    case ValidateFormalName(String)
    case ValidateOptionalRep(String, String)        // label, rep
    case ValidateRep(String, String)                // label, rep
    case ValidateRest(String)
    case ValidateRepRanges(String, String, String, String?) // reps, percent, rest, expected
    
    // Fixed Weights
    case AddExtraWeight(String, Double)
    case AddFixedWeightRange(String, Double, Double, Double)   // fws name, first, step, max
    case ActivateFixedWeightSet(String, Exercise)
    case AddFixedWeight(String, Double)
    case DeactivateFixedWeightSet(Exercise)
    case DeleteExtraWeight(String, Int)
    case DeleteFixedWeight(String, Int)
    case DeleteFixedWeightSet(String)
    case SetFixedWeightSet(String, FixedWeightSet)
    case ValidateExtraWeight(String, String)
    case ValidateFixedWeight(String, String)
    case ValidateFixedWeightRange(String, String, String)   // first, step, max
    case ValidateFixedWeightSetName(String, String)

    // History
    case AppendHistory(Workout, Exercise)
    case DeleteAllHistory(Workout, Exercise)
    case DeleteHistory(Workout, Exercise, History.Record)
    case SetHistoryNote(History.Record, String)
    case SetHistoryWeight(History.Record, Double)

    // Misc
    case NoOp
    case SetUserNote(String, String?)    // formalName, note
    case TimePassed
    case ValidateWeight(String, String)

    // Program
    case AddWorkout(String)
    case DeleteWorkout(Workout)
    case EnableWorkout(Workout, Bool)
    case MoveWorkout(Workout, Int)
    case SetCurrentWeek(Int?)
    case ValidateCurrentWeek(String)
    case ValidateWorkoutName(String, Workout?)
    
    // Programs
    case ActivateProgram(String)
    case AddProgram(Program)
    case DeleteProgram(String)
    case RenameProgram(String, String)
    case ValidateProgramName(String, String)    // old name, new name

    // Workout
    case AddExercise(Workout, Exercise)
    case DelExercise(Workout, Exercise)
    case MoveExercise(Workout, Exercise, Int)
    case PasteExercise(Workout)
    case SetWeeks(Workout, [Int])
    case SetWorkoutName(Workout, String)
    case ToggleWorkoutDay(Workout, WeekDay)
    case ValidateExerciseName(Workout, Exercise?, String)
    case ValidateWeeks(String)
}

/// This is Redux style where Display is serving as the Store object which mediates
/// between views and the model. 
class Display: ObservableObject {
    private(set) var program: Program
    private(set) var history: History
    private(set) var userNotes: [String: String] = [:]    // this overrides defaultNotes
    private(set) var fixedWeights: [String: FixedWeightSet]
    private(set) var programs: [String: String]     // program name => file name
    private(set) var exerciseClipboard: [Exercise] = []
    @Published private(set) var edited = ""         // above should be published but that doesn't work well with classes so we use this lame string to publish chaanges
    @Published private(set) var errMesg = ""        // set when an Action cannot be performed
    @Published private(set) var errColor = Color.black

    init() {
        loadLogs()
        
        var savedFName = "program11"     // historical
        let app = UIApplication.shared.delegate as! AppDelegate
        if let store = app.loadStore(from: "current-program") {
            savedFName = store.getStr("fname")
        }

        if let store = app.loadStore(from: savedFName) {
            self.program = Program(from: store)
        } else {
            self.program = home()   // TODO: should be based on some sort of wizard
        }

        if let store = app.loadStore(from: "history") {
            self.history = History(from: store)
        } else {
            self.history = History()
        }
        if let store = app.loadStore(from: "fws") {
            self.fixedWeights = [:]
            self.fixedWeights = ["Dumbbells": FixedWeightSet([5, 10, 20, 25, 35]), "Cable machine": FixedWeightSet([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])]
            let names = store.getStrArray("fwsKeys")
            for (i, name) in names.enumerated() {
                self.fixedWeights[name] = store.getObj("fwsWeights-\(i)", ifMissing: FixedWeightSet())
            }
        } else {
            // We'll seed the fixedWeights with something semi-useful and more
            // important something that will help clue the user into what this
            // is for.
            self.fixedWeights = ["Dumbbells": FixedWeightSet([5, 10, 20, 25, 35]), "Cable machine": FixedWeightSet([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])]
        }
        if let store = app.loadStore(from: "userNotes") {
            let keys = store.getStrArray("userNoteKeys")
            let values = store.getStrArray("userNoteValues")
            for (i, key) in keys.enumerated() {
                self.userNotes[key] = values[i]
            }
        }

        self.programs = [:]
        if let store = app.loadStore(from: "programs") {
            let names = store.getStrArray("names")
            let fnames = store.getStrArray("fnames")
            for (i, name) in names.enumerated() {
                self.programs[name] = fnames[i]
            }
        } else {
            self.programs[self.program.name] = programNameToFName(self.program.name)
        }
    }
    
    // For testing
    init(_ program: Program, _ history: History, _ weights: [String: FixedWeightSet] = [:], _ programs: [String: String] = [:]) {
        self.program = program
        self.history = history
        self.fixedWeights = weights
        self.programs = programs
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
            
            let fname = programNameToFName(name)
            for (oldName, oldFname) in self.programs {
                if oldName == name {
                    return "There's already a program named '\(oldName)'"
                } else if oldFname == fname {
                    return "Program file name matches that of '\(oldName)'"
                }
            }
            return nil
        }
        
        func checkCurrentWeek(_ text: String) -> String? {
            if text.isBlankOrEmpty() {
                return nil
            }
            
            if let week = Int(text) {
                if week <= 0 {  // TODO: should week be <= numWeeks?
                    return "Current week must be greater than zero"
                } else {
                   return nil
                }
            } else {
                return "Current week should be an integer or empty"
            }
        }
        
        func checkWeeks(_ text: String) -> String? {
            switch parseIntList(text, label: "weeks", emptyOK: true) {
            case .right(_):
                return nil
            case .left(let err):
                return err
            }
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
        
        func checkExpectedRepList(_ text: String) -> String? {
            switch parseRepList(text, label: "expected", emptyOK: true) {
            case .right(_):
                return nil
            case .left(let err):
                return err
            }
        }
        
        func checkFixedReps(_ repsStr: String, _ restStr: String) -> String? {
            switch coalesce(parseFixedRepRanges(repsStr, label: "reps"), parseTimes(restStr, label: "rest", zeroOK: true)) {
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
        
        func checkRest(_ text: String) -> String? {
            switch parseTimes(text, label: "rest", zeroOK: true) {
            case .right(let times):
                if times.count == 1 {
                    return nil
                } else {
                    return "Rest should have one value"
                }
            case .left(let err):
                return err
            }
        }

        func checkRep(_ label: String, _ text: String) -> String? {
            switch parseRep(text, label: label) {
            case .right(_):
                return nil
            case .left(let err):
                return err
            }
        }

        func checkOptionalRep(_ label: String, _ text: String) -> String? {
            switch parseOptionalRep(text, label: label) {
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
        
        func checkExtraWeight(_ name: String, _ str: String) -> String? {
            if let weight = Double(str) {
                if weight <= 0.0 {
                    return "Weight should be larger than zero"
                }
                
                let weights = self.fixedWeights[name] ?? FixedWeightSet()
                if weights.extra.contains(where: {abs(weight - $0) <= 0.01}) {
                    return "Weight already exists"
                }
            } else {
                return "Weight should be a floating point number"
            }
            
            return nil
        }
        
        func checkFixedWeight(_ name: String, _ str: String) -> String? {
            if let weight = Double(str) {
                if weight <= 0.0 {
                    return "Weight should be larger than zero"
                }
                
                let weights = self.fixedWeights[name] ?? FixedWeightSet()
                if weights.weights.contains(where: {abs(weight - $0) <= 0.01}) {
                    return "Weight already exists"
                }
            } else {
                return "Weight should be a floating point number"
            }
            
            return nil
        }
        
        func checkFixedWeightSetRange(_ first: String, _ step: String, _ max: String) -> String? {
            if first.isBlankOrEmpty() {
                return "First must be a weight"
            }
            if !max.isBlankOrEmpty() && step.isBlankOrEmpty() {
                return "If max is set then step must also be set"
            }

            if let f = Double(first) {
                if f < 0.0 {                    // zero can be useful, e.g. rehab using light dumbbell or no dumbbell
                    return "First cannot be negative"
                }

                if max.isBlankOrEmpty() {
                    return nil                  // adding just first
                } else {
                    if let m = Double(max) {
                        if m < f {
                            return "Max cannot be less than first"
                        }

                        if let s = Double(step) {
                            if s <= 0.0 {
                                return "Step should be larger than zero"
                            }
                            return nil
                        } else {
                            return "Step should be a floating point number"
                        }
                    } else {
                        return "Max should be a floating point number"
                    }
                }
            } else {
                return "First should be a floating point number"
            }
        }

        func checkFixedWeightSetName(_ name: String) -> String? {
            if name.isBlankOrEmpty() {
                return "Need a name"
            }
            
            return fixedWeights[name] != nil ? "Name already exists" : nil
        }

        func update() {
            if updateUI {
                self.edited = self.edited.isEmpty ? "\u{200B}" : ""     // toggle between zero-width space and empty
            }
        }
        
        func saveCurentProgram() -> String {
            let store = Store()
            let fname = programNameToFName(self.program.name)
            store.addStr("fname", fname)

            let app = UIApplication.shared.delegate as! AppDelegate
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            do {
                let data = try encoder.encode(store)
                app.saveEncoded(data as AnyObject, to: "current-program")
            } catch {
                log(.Error, "Failed to save current-program: \(error.localizedDescription)")
            }
            return fname
        }
        
        func saveState() {
            func storeFixedWeights(_ app: AppDelegate, to fileName: String) {
                let store = Store()
                
                let names = Array(self.fixedWeights.keys)
                let weights = Array(self.fixedWeights.values)
                store.addStrArray("fwsKeys", names)
                for i in 0..<weights.count {
                    store.addObj("fwsWeights-\(i)", weights[i])
                }

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .secondsSince1970
                do {
                    let data = try encoder.encode(store)
                    app.saveEncoded(data as AnyObject, to: fileName)
                } catch {
                    log(.Error, "Failed to save fixed weights: \(error.localizedDescription)")
                }
            }

            func storeUserNotes(_ app: AppDelegate, to fileName: String) {
                let store = Store()
                store.addStrArray("userNoteKeys", Array(userNotes.keys))
                store.addStrArray("userNoteValues", Array(userNotes.values))

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .secondsSince1970
                do {
                    let data = try encoder.encode(store)
                    app.saveEncoded(data as AnyObject, to: fileName)
                } catch {
                    log(.Error, "Failed to save user notes: \(error.localizedDescription)")
                }
            }

            func storePrograms(_ app: AppDelegate, to fileName: String) {
                let store = Store()
                store.addStrArray("names", Array(programs.keys))
                store.addStrArray("fnames", Array(programs.values))

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .secondsSince1970
                do {
                    let data = try encoder.encode(store)
                    app.saveEncoded(data as AnyObject, to: fileName)
                } catch {
                    log(.Error, "Failed to save programs: \(error.localizedDescription)")
                }
            }
            
            log(.Debug, "Saving state")
            let fname = saveCurentProgram()
            let app = UIApplication.shared.delegate as! AppDelegate
            app.storeObject(self.program, to: fname)
            app.storeObject(self.history, to: "history")
            storeFixedWeights(app, to: "fws")
            storeUserNotes(app, to: "userNotes")
            storePrograms(app, to: "programs")
            
            if numLogErrors > 0 {
                saveLogs()
            } else {
                clearLogs()
            }
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
                log(.Info, "Begin \(name)")
                self.transactions.append(Transaction(name, self))
            } else {
                let names = self.transactions.reversed().map {$0.name}
                let summary = names.joined(separator: ", ")
                log(.Debug, "Skipping begin for \(name), transaction: \(summary)")
            }
            return
        case .RollbackTransaction(let name):
            log(.Info, "Rollback \(name)")
            ASSERT_EQ(name, self.transactions.last!.name, "rollback")
            self.program = self.transactions.last!.program
            self.history = self.transactions.last!.history
            self.fixedWeights = self.transactions.last!.fixedWeights
            self.userNotes = self.transactions.last!.userNotes
            let _ = self.transactions.popLast()
            update()    // state may have changed back so we need to trigger an update
        case .ConfirmTransaction(let name):
            log(.Info, "Confirming \(name)")
            ASSERT_EQ(name, self.transactions.last!.name, "confirm")
            ASSERT(!errors!.hasError, "no error")
            let _ = self.transactions.popLast()
            saveState()

        // Exercise
        case .AdvanceCurrent(let exercise):
            log(.Debug, "AdvanceCurrent \(exercise.name)")
            exercise.current!.setIndex += 1
            update()
        case .AppendCurrent(let exercise, let reps, let percent):
            log(.Debug, "AppendCurrent \(exercise.name) reps: \(reps) percent: \(String(describing: percent))")
            exercise.current!.actualReps.append(reps)
            if let percent = percent {
                exercise.current!.actualPercents.append(percent)
            } else {
                exercise.current!.actualPercents = []
            }
            exercise.current!.setIndex += 1
            update()
        case .CopyExercise(let exercises):
            log(.Debug, "CopyExercise \(exercises.map({$0.name}).joined(separator: " "))")
            exerciseClipboard = exercises
        case .DefaultApparatus(let workout, let exercise, let apparatus):
            if let use = useOriginalApparatus(workout, exercise, apparatus) {
                log(.Debug, "DefaultApparatus \(workout.name) \(exercise.name) original apparatus: \(use)")
                exercise.modality.apparatus = use
            } else {
                log(.Debug, "DefaultApparatus \(workout.name) \(exercise.name) new apparatus: \(apparatus)")
                exercise.modality.apparatus = apparatus
            }
            update()
        case .DefaultSets(let workout, let exercise, let sets):
            if let use = useOriginalSets(workout, exercise, sets) {
                log(.Debug, "DefaultSets \(workout.name) \(exercise.name) original sets: \(use)")
                exercise.modality = Modality(exercise.modality.apparatus, use)
            } else {
                log(.Debug, "DefaultSets \(workout.name) \(exercise.name) new sets: \(sets)")
                exercise.modality = Modality(exercise.modality.apparatus, sets)
            }
            update()
        case .ResetCurrent(let exercise):
            log(.Debug, "ResetCurrent \(exercise.name)")
            let current = Current(weight: exercise.expected.weight)
            exercise.current = current
            update()
        case .SetApparatus(let exercise, let apparatus):
            log(.Debug, "SetApparatus \(exercise.name) apparatus: \(apparatus)")
            exercise.modality.apparatus = apparatus
            update()
        case .SetCompleted(let exercise, let completed):
            log(.Debug, "SetCompleted \(exercise.name) completed: \(completed)")
            exercise.current!.completed = completed
            update()
        case .SetExerciseName(let workout, let exercise, let name):
            log(.Debug, "SetExerciseName \(workout.name) \(exercise.name) name: \(name)")
            ASSERT_NIL(checkExerciseName(workout, name), "SetExerciseName")
            exercise.name = name
            update()
        case .SetExerciseFormalName(let exercise, let name):
            log(.Debug, "SetExerciseFormalName \(exercise.name) name: \(name)")
            ASSERT_NIL(checkFormalName(name), "checkFormalName")
            exercise.formalName = name
            update()
        case .SetExpectedReps(let exercise, let reps):
            log(.Debug, "SetExpectedReps \(exercise.name) reps: \(reps)")
            exercise.expected.reps = reps
            update()
        case .SetExpectedWeight(let exercise, let weight):
            log(.Debug, "SetExpectedWeight \(exercise.name) weight: \(weight)")
            exercise.expected.weight = weight
            update()
        case .SetSets(let exercise, let sets):
            log(.Debug, "SetSets \(exercise.name) sets: \(sets)")
            exercise.modality = Modality(exercise.modality.apparatus, sets)
            update()
        case .ToggleEnableExercise(let exercise):
            log(.Debug, "ToggleEnableExercise \(exercise.name)")
            exercise.enabled = !exercise.enabled
            update()
        case .ValidateDurations(let durations, let target, let rest):
            log(.Debug, "ValidateDurations durations: \(durations) target: \(target) rest: \(rest)")
            if let err = checkDurationsSets(durations, target, rest) {
                errors!.add(key: "set durations sets", error: err)
            } else {
                errors!.reset(key: "set durations sets")
            }
        case .ValidateExpectedRepList(let expected):
            log(.Debug, "ValidateExpectedRepList expected: \(expected)")
            if let err = checkExpectedRepList(expected) {
                errors!.add(key: "set expected reps list", error: err)
            } else {
                errors!.reset(key: "set expected reps list")
            }
        case .ValidateFixedReps(let reps, let rest):
            log(.Debug, "ValidateFixedReps reps: \(reps) rest: \(rest)")
            if let err = checkFixedReps(reps, rest) {
                errors!.add(key: "set fixed reps sets", error: err)
            } else {
                errors!.reset(key: "set fixed reps sets")
            }
        case .ValidateFormalName(let name):
            log(.Debug, "ValidateFormalName name: \(name)")
            if let err = checkFormalName(name) {
                errors!.add(key: "set formal name", warning: err)
            } else {
                errors!.reset(key: "set formal name")
            }
        case .ValidateOptionalRep(let label, let target):
            log(.Debug, "ValidateOptionalRep label: \(label) target: \(target)")
            if let err = checkOptionalRep(label, target) {
                errors!.add(key: "set optional \(label) rep", error: err)
            } else {
                errors!.reset(key: "set optional \(label) rep")
            }
        case .ValidateRep(let label, let target):
            log(.Debug, "ValidateRep label: \(label) target: \(target)")
            if let err = checkRep(label, target) {
                errors!.add(key: "set \(label) rep", error: err)
            } else {
                errors!.reset(key: "set \(label) rep")
            }
        case .ValidateRepRanges(let reps, let percent, let rest, let expected):
            log(.Debug, "ValidateRepRanges reps: \(reps) percent: \(percent) rest: \(rest) expected: \(String(describing: expected))")
            if let err = checkRepRanges(reps, percent, rest, expected) {
                errors!.add(key: "set rep ranges", error: err)
            } else {
                errors!.reset(key: "set rep ranges")
            }
        case .ValidateRest(let rest):
            log(.Debug, "ValidateRest rest: \(rest)")
            if let err = checkRest(rest) {
                errors!.add(key: "set rest", error: err)
            } else {
                errors!.reset(key: "set rest")
            }

        // Fixed Weights
        case .AddFixedWeightRange(let name, let first, let step, let max):
            log(.Debug, "AddFixedWeightRange name: \(name) first: \(first) step: \(step) max: \(max)")
            if self.fixedWeights[name] == nil {
                self.fixedWeights[name] = FixedWeightSet([])
            }
            let fws = self.fixedWeights[name]!
            
            var weight = first
            while weight <= max {
                fws.weights.add(weight)
                weight += step
            }
            update()
        case .ActivateFixedWeightSet(let name, let exercise):
            log(.Debug, "ValidateRest name: \(name) exercise: \(exercise.name)")
            exercise.modality.apparatus = .fixedWeights(name: name)
            update()
        case .AddExtraWeight(let name, let weight):
            log(.Debug, "AddExtraWeight name: \(name) weight: \(weight)")
            if let fws = self.fixedWeights[name] {
                fws.extra.add(weight)
            } else {
                self.fixedWeights[name] = FixedWeightSet([], extra: [weight])
            }
            update()
        case .AddFixedWeight(let name, let weight):
            log(.Debug, "AddFixedWeight name: \(name) weight: \(weight)")
            if let fws = self.fixedWeights[name] {
                fws.weights.add(weight)
            } else {
                self.fixedWeights[name] = FixedWeightSet([weight])
            }
            update()
        case .DeactivateFixedWeightSet(let exercise):
            log(.Debug, "DeactivateFixedWeightSet \(exercise.name)")
            exercise.modality.apparatus = .fixedWeights(name: nil)
            update()
        case .DeleteExtraWeight(let name, let index):
            log(.Debug, "DeleteExtraWeight name: \(name) index: \(index)")
            self.fixedWeights[name]?.extra.remove(at: index)
            update()
        case .DeleteFixedWeight(let name, let index):
            log(.Debug, "DeleteFixedWeight name: \(name) index: \(index)")
            self.fixedWeights[name]?.weights.remove(at: index)
            update()
        case .DeleteFixedWeightSet(let name):
            log(.Debug, "DeleteFixedWeightSet name: \(name)")
            self.fixedWeights[name] = nil
            update()
        case .SetFixedWeightSet(let name, let weights):
            log(.Debug, "SetFixedWeightSet name: \(name) weights: \(weights)")
            fixedWeights[name] = weights
            update()
        case .ValidateExtraWeight(let name, let weight):
            log(.Debug, "ValidateExtraWeight name: \(name) weight: \(weight)")
            if let err = checkExtraWeight(name, weight) {
                errors!.add(key: "set extra weight", error: err)
            } else {
                errors!.reset(key: "set extra weight")
            }
        case .ValidateFixedWeight(let name, let weight):
            log(.Debug, "ValidateFixedWeight name: \(name) weight: \(weight)")
            if let err = checkFixedWeight(name, weight) {
                errors!.add(key: "set fixed weight", error: err)
            } else {
                errors!.reset(key: "set fixed weight")
            }
        case .ValidateFixedWeightRange(let first, let step, let max):
            log(.Debug, "ValidateFixedWeightRange first: \(first) step: \(step) max: \(max)")
            if let err = checkFixedWeightSetRange(first, step, max) {
                errors!.add(key: "set fixed weight sets range", error: err)
            } else {
                errors!.reset(key: "set fixed weight sets range")
            }
        case .ValidateFixedWeightSetName(let originalName, let name):
            log(.Debug, "ValidateFixedWeightSetName originalName: \(originalName) name: \(name)")
            if let err = checkFixedWeightSetName(name), name != originalName {
                errors!.add(key: "set fixed weight sets names", error: err)
            } else {
                errors!.reset(key: "set fixed weight sets names")
            }

        // History
        case .AppendHistory(let workout, let exercise):
            log(.Debug, "AppendHistory \(workout.name) \(exercise.name)")
            self.history.append(workout, exercise)
            if !workout.weeks.isEmpty && self.program.blockStart == nil {
                let delta = workout.weeks.first! - 1
                let date = Calendar.current.date(byAdding: .weekOfYear, value: -delta, to: now())
                self.program.blockStart = date
                if let d = date {
                    print("setting blockStart to week \(Calendar.current.component(.weekOfYear, from: d))")
                } else {
                    print("failed setting blockStart to week")
                }
            }
            saveState()     // most state changes happen via edit views so confirm takes care of the save, but this one is different
            update()
        case .DeleteAllHistory(let workout, let exercise):
            log(.Debug, "DeleteAllHistory \(workout.name) \(exercise.name)")
            self.history.deleteAll(workout, exercise)
            update()
        case .DeleteHistory(let workout, let exercise, let record):
            log(.Debug, "DeleteAllHistory \(workout.name) \(exercise.name) record: \(record)")
            self.history.delete(workout, exercise, record)
            update()
        case .SetHistoryNote(let record, let text):
            log(.Debug, "SetHistoryNote record: \(record) text: \(text)")
            record.note = text
            update()
        case .SetHistoryWeight(let record, let weight):
            log(.Debug, "SetHistoryWeight record: \(record) weight: \(weight)")
            record.weight = weight
            update()

        // Misc
        case .NoOp:
            log(.Debug, "NoOp")
        case .SetUserNote(let formalName, let note):
            log(.Debug, "SetUserNote formalName: \(formalName) note: \(String(describing: note))")
            userNotes[formalName] = note
            update()
        case .TimePassed:
            // Enough time has passed that UIs should be refreshed.
            log(.Debug, "TimePassed")
            update()

        case .ValidateWeight(let weight, let subtype):
            log(.Debug, "ValidateWeight weight: \(weight) subtype: \(subtype)")
            if let err = checkWeight(weight) {
                errors!.add(key: "set \(subtype)", error: err)
            } else {
                errors!.reset(key: "set \(subtype)")
            }

        // Program
        case .AddWorkout(let name):
            log(.Debug, "AddWorkout name: \(name)")
            ASSERT_NIL(checkWorkoutName(name), "AddWorkout")
            let workout = Workout(name, [], days: [])
            self.program.workouts.append(workout)
            update()
        case .DeleteWorkout(let workout):
            log(.Debug, "DeleteWorkout \(workout.name)")
            let index = self.program.workouts.firstIndex(where: {$0 === workout})!
            self.program.workouts.remove(at: index)
            update()
        case .EnableWorkout(let workout, let enable):
            log(.Debug, "EnableWorkout \(workout.name) enable: \(enable)")
            workout.enabled = enable
            update()
        case .SetCurrentWeek(let week):
            log(.Debug, "SetCurrentWeek week: \(String(describing: week))")
            if let w = week {
                self.program.blockStart = Calendar.current.date(byAdding: .weekOfYear, value: -(w - 1), to: now())
                print("setting blockStart to week \(Calendar.current.component(.weekOfYear, from: now()))")
//                log(.Info, "Current week is now \(self.program.currentWeek()!)")    // may not be week (depending on that and numWeeks)
            } else {
                self.program.blockStart = nil
                print("setting blockStart to nil")
            }
            update()
        case .ValidateCurrentWeek(let text):
            log(.Debug, "ValidateCurrentWeek text: \(text)")
            if let err = checkCurrentWeek(text) {
                errors!.add(key: "set current week", error: err)
            } else {
                errors!.reset(key: "set current week")
            }
        case .MoveWorkout(let workout, let by):
            log(.Debug, "MoveWorkout \(workout.name) by: \(by)")
            ASSERT_NE(by, 0, "MoveWorkout")
            let index = self.program.workouts.firstIndex(where: {$0 === workout})!
            let _ = self.program.workouts.remove(at: index)
            self.program.workouts.insert(workout, at: index + by)
            update()
        case .ValidateWorkoutName(let name, let workout):
            log(.Debug, "MoveWorkout name: \(name) workout: \(workout?.name ?? "nil")")
            if let workout = workout, workout.name == name {
                errors!.reset(key: "add workout")
                return
            }
            if let err = checkWorkoutName(name) {
                errors!.add(key: "add workout", error: err)
            } else {
                errors!.reset(key: "add workout")
            }

        // Programs
        case .ActivateProgram(let name):
            log(.Debug, "ActivateProgram name: \(name)")
            ASSERT_NE(name, self.program.name, "ActivateProgram")
            ASSERT_NOT_NIL(self.programs[name], "ActivateProgram")
            let fname = programNameToFName(name)
            let app = UIApplication.shared.delegate as! AppDelegate
            if let store = app.loadStore(from: fname) {
                saveState()
                self.program = Program(from: store)
                update()
            }
        case .AddProgram(let program):
            log(.Debug, "AddProgram program: \(program.name)")
            ASSERT_NE(program.name, self.program.name, "AddProgram")
            ASSERT_NIL(self.programs[program.name], "AddProgram")
            let fname = programNameToFName(program.name)
            let app = UIApplication.shared.delegate as! AppDelegate
            app.storeObject(program, to: fname)
            self.programs[program.name] = fname
            update()
        case .DeleteProgram(let name):
            log(.Debug, "DeleteProgram name: \(name)")
            ASSERT_NE(name, self.program.name, "DeleteProgram")
            let fname = programNameToFName(name)
            if let url = fileNameToURL(fname) {
                do {
                    try FileManager.default.removeItem(at: url)
                    self.programs[name] = nil
                    update()
                } catch {
                    log(.Warning, "Failed to delete \(name): \(error.localizedDescription)")
                }
            }
        case .RenameProgram(let oldName, let newName):
            log(.Debug, "RenameProgram oldName: \(oldName) newName: \(newName)")
            ASSERT_NE(oldName, newName, "RenameProgram")
            ASSERT_NOT_NIL(self.programs[oldName], "RenameProgram")
            ASSERT_NIL(self.programs[newName], "RenameProgram")
            
            do {
                let oldFname = programNameToFName(oldName)
                let newFname = programNameToFName(newName)
                if let oldUrl = fileNameToURL(oldFname), let newUrl = fileNameToURL(newFname) {
                    try FileManager.default.moveItem(at: oldUrl, to: newUrl)
                    self.programs[oldName] = nil
                    self.programs[newName] = newFname
                    if oldName == self.program.name {
                        self.program.name = newName
                    }
                    update()
                }
            } catch {
                log(.Error, "Failed to rename \(oldName) to \(newName): \(error.localizedDescription)")
            }
        case .ValidateProgramName(let oldName, let newName):
            log(.Debug, "ValidateProgramName oldName: \(oldName) newName: \(newName)")
            if !oldName.isBlankOrEmpty() && oldName == newName {
                errors!.reset(key: "add program")
            } else {
                if let err = checkProgramName(newName) {
                    errors!.add(key: "add program", error: err)
                } else {
                    errors!.reset(key: "add program")
                }
            }

        // Workout
        case .AddExercise(let workout, let exercise):
            log(.Debug, "AddExercise \(workout.name) exercise: \(exercise.name)")
            workout.exercises.append(exercise)
            update()
        case .DelExercise(let workout, let exercise):
            log(.Debug, "DelExercise \(workout.name) exercise: \(exercise.name)")
            let index = workout.exercises.firstIndex(where: {$0 === exercise})!
            workout.exercises.remove(at: index)
            update()
        case .MoveExercise(let workout, let exercise, let by):
            log(.Debug, "MoveExercise \(workout.name) exercise: \(exercise.name) by: \(by)")
            let index = workout.exercises.firstIndex(where: {$0 === exercise})!
            workout.moveExercise(index, by: by)
            update()
        case .PasteExercise(let workout):
            log(.Debug, "PasteExercise \(workout.name)")
            for exercise in self.exerciseClipboard {
                let exercise = exercise.copy()     // copy so pasting twice doesn't add the same exercise
                exercise.name = newExerciseName(workout, exercise.name)
                workout.exercises.append(exercise)
            }
            update()
        case .SetWeeks(let workout, let weeks):
            log(.Debug, "SetWeeks \(workout.name) weeks: \(weeks)")
            workout.weeks = weeks.sorted()
            update()
        case .SetWorkoutName(let workout, let name):
            log(.Debug, "SetWorkoutName \(workout.name) name: \(name)")
            ASSERT_NIL(checkWorkoutName(name), "SetWorkoutName")
            workout.name = name
            update()
        case .ToggleWorkoutDay(let workout, let day):
            log(.Debug, "ToggleWorkoutDay \(workout.name) day: \(day)")
            workout.days[day.rawValue] = !workout.days[day.rawValue]
            update()
        case .ValidateExerciseName(let workout, let exercise, let name):
            log(.Debug, "ValidateExerciseName \(workout.name) \(String(describing: exercise?.name)) name: \(name)")
            if let exercise = exercise, exercise.name == name {
                errors!.reset(key: "add exercise")
                return
            }
            if let err = checkExerciseName(workout, name) {
                errors!.add(key: "add exercise", error: err)
            } else {
                errors!.reset(key: "add exercise")
            }
        case .ValidateWeeks(let weeks):
            log(.Debug, "ValidateWeeks weeks: \(weeks)")
            if let err = checkWeeks(weeks) {
                errors!.add(key: "add weeks", error: err)
            } else {
                errors!.reset(key: "add weeks")
            }
        }

        let (err, color) = self.transactions.last?.errors.getError() ?? ("", .black)
        if err != self.errMesg || color != self.errColor {
            self.errMesg = err
            self.errColor = color
        }
    }
    
    private func findOriginalExercise(_ transaction: Transaction, _ workout: Workout, _ exercise: Exercise) -> Exercise? {
        if let originalWorkout = transaction.program.workouts.first(where: {$0.name == workout.name}) {
            let originalExercise = originalWorkout.exercises.first(where: {$0.name == exercise.name})
            return originalExercise
        }
        return nil
    }
    
    // When setting apparatus or sets the user may switch back to what he originally had. In this
    // case we don't want to lose the associated enum values he may have been using.
    private func useOriginalSets(_ workout: Workout, _ exercise: Exercise, _ sets: Sets) -> Sets? {
        if let transaction = self.transactions.last {
            if let original = findOriginalExercise(transaction, workout, exercise) {
                if sets.sameCase(original.modality.sets) {
                    return original.modality.sets
                }
            }
        }
        return nil
    }

    private func useOriginalApparatus(_ workout: Workout, _ exercise: Exercise, _ apparatus: Apparatus) -> Apparatus? {
        if let transaction = self.transactions.last {
            if let original = findOriginalExercise(transaction, workout, exercise) {
                if apparatus.sameCase(original.modality.apparatus) {
                    return original.modality.apparatus
                }
            }
        }
        return nil
    }

    private func programNameToFName(_ name: String) -> String {
        // Program names may not work as file names so we sanitize them here.
        // The "program11" helps distinguish programs from other saved objects (the name is for historical reasons).
        return "program11-" + name.toFileName()
    }

    private struct Transaction {
        let name: String
        let program: Program
        let history: History
        let fixedWeights: [String: FixedWeightSet]
        let userNotes: [String: String]
        let errors = ActionErrors()
        
        init(_ name: String, _ display: Display) {
            self.name = name
            self.program = display.program.clone()
            self.history = display.history.clone()
            
            var weights: [String: FixedWeightSet] = [:]
            for (name, set) in display.fixedWeights {
                weights[name] = set.clone()
            }
            self.fixedWeights = weights
            self.userNotes = display.userNotes
        }
    }
    
    // This is used to avoid losing UI errors as the user switches context. For example if there are A
    // and B text fields and each has validation upon changes then without this class the user could have
    // an error on editing A that is lost if the user switches to B without fixing the problem.
    private class ActionErrors {
        func add(key: String, error inMesg: String) {
            ASSERT(!key.isEmpty, "key is empty")
            ASSERT(!inMesg.isEmpty, "inMesg is empty")
            
            var mesg = inMesg
            if !mesg.hasSuffix(".") {
                mesg += "."
            }
            
            errors[key] = mesg
            warnings[key] = nil
        }
        
        func add(key: String, warning inMesg: String) {
            ASSERT(!key.isEmpty, "key is empty")
            ASSERT(!inMesg.isEmpty, "inMesg is empty")

            var mesg = inMesg
            if !mesg.hasSuffix(".") {
                mesg += "."
            }
            
            errors[key] = nil
            warnings[key] = mesg
        }
        
        func reset(key: String) {
            ASSERT(!key.isEmpty, "key is empty")

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
