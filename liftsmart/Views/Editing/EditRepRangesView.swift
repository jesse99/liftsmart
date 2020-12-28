//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditRepRangesView: View, EditContext {
    enum ActiveSheet {case formalName, editReps}

    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var weight = "0.0"
    @State var errText = ""
    @State var errColor = Color.red
    @State var showHelp = false
    @State var repsSetName = ""
    @State var repsSet = [RepsSet(reps: RepRange(10))]
    @State var helpText = ""
    @State var formalNameModal = false  // crappy name needed to conform to EditContext
    @State var sheetAction: EditRepRangesView.ActiveSheet = .formalName
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, exercise: Exercise) {
        self.workout = workout
        self.exercise = exercise
        self.original = exercise.clone()
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle)

            VStack(alignment: .leading) {
                createNameView(text: self.$name, self)
                HStack {        // better to use createFormalNameView but that doesn't quite work with multiple sheets
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {self.formalNameModal = true; self.sheetAction = .formalName})
                        .font(.callout)
                    Spacer()
                    Button("?", action: {formalNameHelp(self)}).font(.callout).padding(.trailing)
                }.padding(.leading)
                createWeightView(text: self.$weight, self)
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
                if self.sheetAction == .formalName {
                    PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: {editedFormalName($0, self)})
                } else {
                    EditRepsSetView(name: self.$repsSetName, set: self.$repsSet, completion: self.doSetReps)
                }
            }
            Spacer()
            Text(self.errText).foregroundColor(.red).font(.callout).padding(.leading)

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
        self.name = exercise.name
        self.formalName = exercise.formalName.isEmpty ? "none" : exercise.formalName
        self.weight = String(format: "%.3f", exercise.expected.weight)
    }
        
    func onWarmups() {
        self.formalNameModal = true
        self.sheetAction = .editReps
        self.repsSetName = "Warmup"
        switch exercise.modality.sets {
        case .repRanges(warmups: let s, worksets: _, backoffs: _):
            self.repsSet = s
        default:
            assert(false)
        }
    }
    
    func onWorkSets() {
        self.formalNameModal = true
        self.sheetAction = .editReps
        self.repsSetName = "Work Sets"
        switch exercise.modality.sets {
        case .repRanges(warmups: _, worksets: let s, backoffs: _):
            self.repsSet = s
        default:
            assert(false)
        }
    }
    
    func onBackoff() {
        self.formalNameModal = true
        self.sheetAction = .editReps
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
                } else {
                    // TODO: this will be cleared if the user switches to editing something like Name.
                    // Simple way to fix this might be to replace errText with some sort of class:
                    // 1) Stores multiple errors,
                    // 2) Renders the most recent error,
                    // 3) Associates each error with some sort of key,
                    self.errText = "Work Sets cannot be empty"
                    self.errColor = .red
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
        return !self.errText.isEmpty && self.errColor == .red
    }
            
    func onCancel() {
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.exercise.name = self.name.trimmingCharacters(in: .whitespaces)
        self.exercise.formalName = self.formalName
        self.exercise.expected.weight = Double(self.weight)!
        
//        exercise.modality.sets = .repRanges(warmups: _, worksets: _, backoffs: _)

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

