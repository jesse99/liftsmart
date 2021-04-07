//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

protocol ExerciseContext {
    var showHelp: Bool {get set}
    var helpText: String {get set}
}

func exerciseNameView(_ context: ExerciseContext, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void) -> some View {
    func nameHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "Your name for the exercise, e.g. 'Light OHP'."
        context.showHelp = true
    }

    return HStack {
        Text("Name:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.default)
            .disableAutocorrection(true)
            .autocapitalization(.words)
            .onChange(of: text.wrappedValue, perform: onEdit)
        Button("?", action: {nameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func exerciseFormalNameView(_ context: ExerciseContext, _ text: Binding<String>, _ modal: Binding<Bool>, _ onEdit: @escaping (String) -> Void) -> some View {
    func matchFormalName(_ inText: String) -> [String] {
        var names: [String] = []
        
        // TODO: better to do a proper fuzzy search
        let needle = inText.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()

        // First match any custom names defined by the user.
        for candidate in userNotes.keys {
            if defaultNotes[candidate] == nil {
                let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
                if haystack.contains(needle) {
                    names.append(candidate)
                }
            }
        }
        
        // Then match the standard names.
        for candidate in defaultNotes.keys {
            let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
            if haystack.contains(needle) {
                names.append(candidate)
            }
            
            // Not much point in showing the user a huge list of names.
            if names.count >= 100 {
                break
            }
        }

        return names
    }
    
    func onEdited(_ inText: String) {
        text.wrappedValue = inText
        onEdit(inText)
    }

    func formalNameHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
        context.showHelp = true
    }

    return HStack {
        Text("Formal Name:").font(.headline)
        Button(text.wrappedValue, action: {modal.wrappedValue = true})
            .font(.callout)
            .sheet(isPresented: modal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: text.wrappedValue, populate: matchFormalName, confirm: onEdited)}
        Spacer()
        Button("?", action: {formalNameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func exerciseWeightView(_ context: ExerciseContext, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void) -> some View {
    func weightHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
        context.showHelp = true
    }

    // Probably want to handle weight differently for different apparatus. For example, for barbell
    // could use a picker like formal name uses: user can type in a weight and then is able to see
    // all the nearby weights and select one if he wants.
    return HStack {
        Text("Weight:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .disableAutocorrection(true)
            .onChange(of: text.wrappedValue, perform: onEdit)
        Button("?", action: {weightHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func exerciseRestView(_ context: ExerciseContext, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void) -> some View {
    func resttHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        context.showHelp = true
    }

    return HStack {
        Text("Rest:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.default)
            .disableAutocorrection(true)
            .onChange(of: text.wrappedValue, perform: onEdit)
        Button("?", action: {resttHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

struct EditDurationsView: View, ExerciseContext {
    let workout: Workout
    let exercise: Exercise
    @State var name: String
    @State var formalName: String
    @State var weight: String
    @State var durations: String
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
                exerciseNameView(self, self.$name, self.onEditedName)
                exerciseFormalNameView(self, self.$formalName, self.$formalNameModal, self.onEditedFormalName)
                exerciseWeightView(self, self.$weight, self.onEditedWeight)
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
                exerciseRestView(self, self.$rest, self.onEditedSets)
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

