//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditRepRangesView: View, ExerciseContext {
    let workout: Workout
    let exercise: Exercise
    @State var name: String
    @State var formalName: String
    @State var weight: String
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
    @State var repsModal = false
    @State var repsKind = EditRepsSetView.Kind.Warmup
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise) {
        self.display = display
        self.workout = workout
        self.exercise = exercise

        self._name = State(initialValue: exercise.name)
        self._formalName = State(initialValue: exercise.formalName.isEmpty ? "none" : exercise.formalName)
        self._weight = State(initialValue: String(format: "%.3f", exercise.expected.weight))
        
        self.display.send(.BeginTransaction(name: "change rep ranges"))
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                exerciseNameView(self, self.$name, self.onEditedName)
                exerciseFormalNameView(self, self.$formalName, self.$formalNameModal, self.onEditedFormalName)
                exerciseWeightView(self, self.$weight, self.onEditedWeight)
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
                    .sheet(isPresented: self.$repsModal) {EditRepsSetView(self.display, self.exercise, self.repsKind)}
                }
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
    
    private func onWarmups() {
        self.repsModal = true
        self.repsKind = .Warmup
    }
    
    private func onWorkSets() {
        self.repsModal = true
        self.repsKind = .WorkSets
    }
    
    private func onBackoff() {
        self.repsModal = true
        self.repsKind = .Backoff
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

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change rep ranges"))
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
        
        self.display.send(.ConfirmTransaction(name: "change rep ranges"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepRangesView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[1]
    static let exercise = workout.exercises.first(where: {$0.name == "Split Squat"})!

    static var previews: some View {
        EditRepRangesView(display, workout, exercise)
    }
}

