//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditDurationsView: View {
    let workout: Workout
    var exercise: Exercise
    @State var name: String
    @State var formalName: String
    @State var weight: String
    @State var durations: String
    @State var target: String
    @State var rest: String
    @State var errMesg = ""
    @State var errColor = Color.black
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
        
        switch exercise.modality.sets {
        case .durations(let d, targetSecs: let t):
            self._durations = State(initialValue: d.map({restToStr($0.secs)}).joined(separator: " "))
            self._rest = State(initialValue: d.map({restToStr($0.restSecs)}).joined(separator: " "))
            self._target = State(initialValue: t.map({restToStr($0)}).joined(separator: " "))
        default:
            self._durations = State(initialValue: "")
            self._rest = State(initialValue: "")
            self._target = State(initialValue: "")
            assert(false)
        }

        self.display.send(.BeginTransaction(name: "change durations"))
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())  // TODO: custom view modifier?
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .autocapitalization(.words)
                        .onChange(of: self.name, perform: self.onEditedName)
                    Button("?", action: self.onNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {self.formalNameModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$formalNameModal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: self.onEditedFormalName)}
                    Spacer()
                    Button("?", action: self.onFormalNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    // Probably want to handle weight differently for different apparatus. For example, for barbell
                    // could use a picker like formal name uses: user can type in a weight and then is able to see
                    // all the nearby weights and select one if he wants.
                    Text("Weight:").font(.headline)
                    TextField("", text: self.$weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.weight, perform: self.onEditedWeight)
                Button("?", action: self.onWeightHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Durations:").font(.headline)
                    TextField("", text: self.$durations)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.durations, perform: self.onEditedSets)
                    Button("?", action: self.onDurationsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Target:").font(.headline)
                    TextField("", text: self.$target)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.target, perform: self.onEditedSets)
                    Button("?", action: self.onTargetHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rest, perform: self.onEditedSets)
                    Button("?", action: self.onRestHelp).font(.callout).padding(.trailing)
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

    private func onEditedSets(_ text: String) {
        self.display.send(.ValidateDurations(self.durations, self.target, self.rest))
    }
    
    private func onNameHelp() {
        self.helpText = "Your name for the exercise, e.g. 'Light OHP'."
        self.showHelp = true
    }

    private func onFormalNameHelp() {
        self.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
        self.showHelp = true
    }

    private func onWeightHelp() {
        self.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
        self.showHelp = true
    }

    private func onRestHelp() {
        self.helpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        self.showHelp = true
    }

    func onDurationsHelp() {
        self.helpText = "The amount of time to perform each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        self.showHelp = true
    }

    func onTargetHelp() {
        self.helpText = "Optional goal time for each set. Often when reaching the target a harder variation of the exercise is used."
        self.showHelp = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change durations"))
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
        
        let durations = parseTimes(self.durations, label: "durations").unwrap()
        let rest = parseTimes(self.rest, label: "rest", zeroOK: true).unwrap()
        let target = parseTimes(self.target, label: "target").unwrap()
        let sets = zip(durations, rest).map({DurationSet(secs: $0, restSecs: $1)})
        let dsets = Sets.durations(sets, targetSecs: target)
        if dsets != self.exercise.modality.sets {
            self.display.send(.SetSets(self.exercise, dsets))
        }

        self.display.send(.ConfirmTransaction(name: "change durations"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditDurationsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Planks"})!

    static var previews: some View {
        EditDurationsView(display, workout, exercise)
    }
}

