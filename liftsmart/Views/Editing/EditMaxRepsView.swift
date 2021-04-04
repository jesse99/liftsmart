//  Created by Jesse Jones on 10/23/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditMaxRepsView: View, ExerciseContext {
    let workout: Workout
    let exercise: Exercise
    @State var name: String
    @State var formalName: String
    @State var reps: String
    @State var weight: String
    @State var target: String
    @State var rest: String
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise) {
        self.display = display
        self.workout = workout
        self.exercise = exercise

        self._name = State(initialValue: exercise.name)
        self._formalName = State(initialValue: exercise.formalName.isEmpty ? "none" : exercise.formalName)
        self._weight = State(initialValue: String(format: "%.3f", exercise.expected.weight))
        
        self._reps = State(initialValue: exercise.expected.reps.isEmpty ? "" : "\(exercise.expected.reps[0])")
        
        switch exercise.modality.sets {
        case .maxReps(restSecs: let r, targetReps: let t):
            self._rest = State(initialValue: r.map({restToStr($0)}).joined(separator: " "))
            self._target = State(initialValue: t != nil ? "\(t!)" : "")
        default:
            self._rest = State(initialValue: "")
            self._target = State(initialValue: "")
            assert(false)
        }

        self.display.send(.BeginTransaction(name: "change max reps"))
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                exerciseNameView(self, self.$name, self.onEditedName)
                exerciseFormalNameView(self, self.$formalName, self.$formalNameModal, self.onEditedFormalName)
                exerciseWeightView(self, self.$weight, self.onEditedWeight)
                exerciseRestView(self, self.$rest, self.onEditedReps)
                HStack {
                    Text("Expected Reps:").font(.headline)
                    TextField("", text: self.$reps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.reps, perform: self.onEditedReps)
                    Button("?", action: onRepsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Target Reps:").font(.headline)
                    TextField("", text: self.$target)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.target, perform: self.onEditedTarget)
                    Button("?", action: onTargetHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                // apparatus (conditional)
            }
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    private func onEditedName(_ text: String) {
        self.display.send(.ValidateExerciseName(self.workout, text))
    }

    private func onEditedFormalName(_ text: String) {
        self.display.send(.ValidateFormalName(text))    // shouldn't ever fail
    }

    private func onEditedWeight(_ text: String) {
        self.display.send(.ValidateWeight(text, "weight"))
    }

    func onEditedReps(_ text: String) {
        self.display.send(.ValidateMaxReps(text))
    }
    
    func onEditedTarget(_ text: String) {
        self.display.send(.ValidateMaxRepsTarget(text))
    }
        
    func onRepsHelp() {
        self.helpText = "The number of reps you expect to do across all the sets, e.g. '60'. Can be empty."
        self.showHelp = true
    }
        
    func onTargetHelp() {
        self.helpText = "The goal for this particular exercise. Often when the goal is reached weight is increased or a harder variant of the exercise is used. Empty means that there is no target."
        self.showHelp = true
    }
    
    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change max reps"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {        
        if self.formalName != self.exercise.formalName {
            self.display.send(.SetExerciseFormalName(self.exercise, self.formalName))
        }
        if self.name != self.exercise.name {
            self.display.send(.SetExerciseName(self.workout, self.exercise, self.name))
        }
        
        let weight = Double(self.weight)!
        if weight != self.exercise.expected.weight {
            self.display.send(.SetExpectedWeight(self.exercise, weight))
        }
        
        if let reps = parseOptionalRep(self.reps, label: "reps").unwrap(), [reps] != self.exercise.expected.reps {
            self.display.send(.SetExpectedReps(self.exercise, [reps]))
        }
        
        let target = parseOptionalRep(self.target, label: "target").unwrap()
        let rest = parseTimes(self.rest, label: "rest", zeroOK: true).unwrap()
        let msets = Sets.maxReps(restSecs: rest, targetReps: target)
        if msets != self.exercise.modality.sets {
            self.display.send(.SetSets(self.exercise, msets))
        }

        self.display.send(.ConfirmTransaction(name: "change max reps"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditMaxRepsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Curls"})!

    static var previews: some View {
        EditMaxRepsView(display, workout, exercise)
    }
}

