//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// TODO: Didn't work when used as a @State field...
var sheetAction: EditRepRangesView.ActiveSheet = .formalName

struct EditRepRangesView: View, EditContext {
    enum ActiveSheet {case formalName, editReps}

    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var weight = "0.0"
    @State var expectedReps = ""
    @State var error = ViewError()
    @State var errMesg = ""
    @State var errColor = Color.black
    @State var showHelp = false
    @State var repsSetName = ""
    @State var repsSet = [RepsSet(reps: RepRange(10))]
    @State var helpText = ""
    @State var formalNameModal = false  // crappy name needed to conform to EditContext
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, exercise: Exercise) {
        self.workout = workout
        self.exercise = exercise
        self.original = exercise.clone()
        self.original.id = exercise.id
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle)

            VStack(alignment: .leading) {
                createNameView(text: self.$name, self)
                HStack {        // better to use createFormalNameView but that doesn't quite work with multiple sheets
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {sheetAction = .formalName; self.formalNameModal = true})
                        .font(.callout)
                    Spacer()
                    Button("?", action: {formalNameHelp(self)}).font(.callout).padding(.trailing)
                }.padding(.leading)
                createWeightView(text: self.$weight, self)
                HStack {
                    Text("Expected Reps:").font(.headline)
                    TextField("", text: self.$expectedReps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.expectedReps, perform: self.onEditedExpected)
                    Button("?", action: onExpectedHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button("Warmups", action: self.onWarmups).font(.callout)
                        Spacer()
                        Button("?", action: {
                            self.helpText = "Optional sets to be done with a lighter weight."
                            self.showHelp = true
                        }).font(.callout).padding(.trailing)
                    }.padding(.leading)
                    HStack {
                        Button("Work Sets", action: self.onWorkSets).font(.callout)
                        Spacer()
                        Button("?", action: {
                            self.helpText = "Sets to be done with 100% or so of the weight."
                            self.showHelp = true
                        }).font(.callout).padding(.trailing)
                    }.padding(.leading)
                    HStack {
                        Button("Backoff", action: self.onBackoff).font(.callout)
                        Spacer()
                        Button("?", action: {
                            self.helpText = "Optional sets to be done with a reduced weight."
                            self.showHelp = true
                        }).font(.callout).padding(.trailing)
                    }.padding(.leading)
                }
                // apparatus (conditional)
            }
            .sheet(isPresented: self.$formalNameModal) {
                if sheetAction == .formalName {
                    PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: {editedFormalName($0, self)})
                } else {
                    EditRepsSetView(name: self.$repsSetName, set: self.$repsSet, completion: self.doSetReps)
                }
            }
            Spacer()
            Text(self.errMesg).foregroundColor(self.errColor).font(.callout).padding(.leading)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.hasError())
            }
            .padding()
            .onAppear {self.refresh()}
        }
//        .modifier(ShowHelp(showing: $showHelp, context: self))
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func refresh() {
        self.error.set(self.$errMesg, self.$errColor)

        self.name = exercise.name
        self.formalName = exercise.formalName.isEmpty ? "none" : exercise.formalName
        self.weight = String(format: "%.3f", exercise.expected.weight)
        self.expectedReps = exercise.expected.reps.map({$0.description}).joined(separator: " ")
    }
    
    func checkSetCounts() {
        switch parseReps(self.expectedReps, label: "expected", emptyOK: true) {
        case .right(let expected):
            switch exercise.modality.sets {
            case .repRanges(warmups: _, worksets: let work, backoffs: _):
                if !expected.isEmpty && work.count != expected.count {
                    self.error.add(key: "ZGlobal", error: "Number of expected reps should match work sets (or be empty)")
                } else {
                    self.error.reset(key: "ZGlobal")
                }
            default:
                assert(false)
            }
        case .left(let err):
            self.error.add(key: "ZGlobal", error: err)
        }
    }
        
    func onEditedExpected(_ text: String) {
        switch parseReps(text, label: "expected", emptyOK: true) {
        case .right(let reps):
            self.error.reset(key: "Expected")
            checkSetCounts()
            if self.error.isEmpty {
                self.exercise.expected.reps = reps
            }
        case .left(let err):
            self.error.add(key: "Expected", error: err)
        }
    }

    func onExpectedHelp() {
        self.helpText = "The number of reps you expect to do for each work set. Can be empty."
        self.showHelp = true
    }

    func onWarmups() {
        sheetAction = .editReps
        self.formalNameModal = true
        self.repsSetName = "Warmup"
        switch exercise.modality.sets {
        case .repRanges(warmups: let s, worksets: _, backoffs: _):
            self.repsSet = s
        default:
            assert(false)
        }
    }
    
    func onWorkSets() {
        sheetAction = .editReps
        self.formalNameModal = true
        self.repsSetName = "Work Sets"
        switch exercise.modality.sets {
        case .repRanges(warmups: _, worksets: let s, backoffs: _):
            self.repsSet = s
        default:
            assert(false)
        }
    }
    
    func onBackoff() {
        sheetAction = .editReps
        self.formalNameModal = true
        self.repsSetName = "Backoff"
        switch exercise.modality.sets {
        case .repRanges(warmups: _, worksets: _, backoffs: let s):
            self.repsSet = s
        default:
            assert(false)
        }
    }
    
    func doSetReps(_ sets: [RepsSet]) {
        switch self.repsSetName {
        case "Warmup":
            switch exercise.modality.sets {
            case .repRanges(warmups: _, worksets: let work, backoffs: let back):
                self.exercise.modality.sets = .repRanges(warmups: sets, worksets: work, backoffs: back)
            default:
                assert(false)
            }
        case "Work Sets":
            switch exercise.modality.sets {
            case .repRanges(warmups: let warm, worksets: _, backoffs: let back):
                if sets.count >= 1 {
                    self.exercise.modality.sets = .repRanges(warmups: warm, worksets: sets, backoffs: back)
                    checkSetCounts()
                } else {
                    self.error.add(key: "Reps", error: "Work Sets cannot be empty")
                }
            default:
                assert(false)
            }
        case "Backoff":
            switch exercise.modality.sets {
            case .repRanges(warmups: let warm, worksets: let work, backoffs: _):
                self.exercise.modality.sets = .repRanges(warmups: warm, worksets: work, backoffs: sets)
            default:
                assert(false)
            }

        default:
            assert(false)
        }
        refresh()
    }
    
    func hasError() -> Bool {
        return !self.error.isEmpty
    }
            
    func onCancel() {
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepRangesView_Previews: PreviewProvider {
    static func splitSquats() -> Exercise {
        let warmup = RepsSet(reps: RepRange(4), percent: WeightPercent(0.0), restSecs: 90)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60)
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }

    static let workout = createWorkout("Strength", [splitSquats()], day: nil).unwrap()

    static var previews: some View {
        EditRepRangesView(workout: workout, exercise: workout.exercises[0])
    }
}

