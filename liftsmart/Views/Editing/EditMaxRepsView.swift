//  Created by Jesse Jones on 10/23/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditMaxRepsView: View, NameContext {
    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var reps = ""
    @State var weight = "0.0"
    @State var target = ""
    @State var rest = ""
    @State var errText = ""
    @State var errColor = Color.red
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
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
                createnameView(text: self.$name, self)
                HStack {
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {self.formalNameModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$formalNameModal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: self.onMatchFormalName, confirm: onEditedFormalName)}
                    Spacer()
                    Button("?", action: onFormalNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Weight:").font(.headline)
                    TextField("", text: self.$weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.weight, perform: self.onEditedWeight)
                    Button("?", action: onWeightHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Reps:").font(.headline)
                    TextField("", text: self.$reps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.reps, perform: self.onEditedReps)
                    Button("?", action: onRepsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rest, perform: self.onEditedRest)
                    Button("?", action: onRestHelp).font(.callout).padding(.trailing)
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
        self.reps = exercise.expected.reps.isEmpty ? "" : "\(exercise.expected.reps[0])"
        self.weight = String(format: "%.3f", exercise.expected.weight)
        
        switch exercise.modality.sets {
        case .maxReps(restSecs: let r, targetReps: let t):
            self.rest = r.map({restToStr($0)}).joined(separator: " ")
            self.target = t != nil ? "\(t!)" : ""
        default:
            assert(false)
        }
    }
    
    func hasError() -> Bool {
        return !self.errText.isEmpty && self.errColor == .red
    }
    
    func onMatchFormalName(_ inText: String) -> [String] {
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
    
    func onEditedFormalName(_ text: String) {
        self.formalName = text
    }
    
    func onEditedReps(_ text: String) {
        if let reps = Int(text) {
            if reps <= 0 {
                self.errText = "Reps should be greater than zero (found \(reps))"
                self.errColor = .red
            } else {
                self.errText = ""
            }
        } else {
            self.errText = "Expected a number for reps (found '\(text)')"
            self.errColor = .red
        }
    }
    
    func onEditedWeight(_ text: String) {
        if let weight = Double(text) {
            if weight < 0.0 {
                self.errText = "Weight cannot be negative (found \(weight))"
                self.errColor = .red
            } else {
                self.errText = ""
            }
        } else {
            self.errText = "Expected a floating point number for weight (found '\(text)')"
            self.errColor = .red
        }
    }
    
    func onEditedRest(_ inText: String) {
        // Note that we don't use comma separated lists because that's more visual noise and
        // because some locales use commas for the decimal points.
        let text = inText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            self.errText = "Rest needs at least one set"
            self.errColor = .red
            return
        }
        for token in text.split(separator: " ") {
            switch strToRest(String(token)) {
            case .right(_):
                self.errText = ""
            case .left(let err):
                self.errText = err
                self.errColor = .red
                return                  // bail on the first error
            }
        }
    }

    func onEditedTarget(_ inText: String) {
        let text = inText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            return
        }
        if let reps = Int(text) {
            if reps <= 0 {
                self.errText = "Target reps should be greater than zero (found \(reps))"
                self.errColor = .red
            } else {
                self.errText = ""
            }
        } else {
            self.errText = "Expected a number for target reps (found '\(text)')"
            self.errColor = .red
        }
    }
    
    func onFormalNameHelp() {
        self.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
        self.showHelp = true
    }
    
    func onRepsHelp() {
        self.helpText = "The number of reps you expect to do across all the sets, e.g. '60'."
        self.showHelp = true
    }
    
    // TODO:
    // Probably want to handle weight differently for different apparatus. For example, for barbell
    // could use a picker like formal name uses: user can type in a weight and then is able to see
    // all the nearby weights and select one if he wants.
    func onWeightHelp() {
        self.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
        self.showHelp = true
    }
    
    func onRestHelp() {
        self.helpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        self.showHelp = true
    }
    
    func onTargetHelp() {
        self.helpText = "The goal for this particular exercise. Often when the goal is reached weight is increased or a harder variant of the exercise is used. Empty means that there is no target,"
        self.showHelp = true
    }
    
    func onCancel() {
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.exercise.name = self.name.trimmingCharacters(in: .whitespaces)
        self.exercise.formalName = self.formalName
        self.exercise.expected.reps = self.reps.isEmpty ? [] : [Int(self.reps)!]    // TODO: use isEmptyOrBlank
        self.exercise.expected.weight = Double(self.weight)!
        
        let target = Int(self.target)
        let rest = self.rest.split(separator: " ").map({strToRest(String($0)).unwrap()})
        exercise.modality.sets = .maxReps(restSecs: rest, targetReps: target)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditMaxRepsView_Previews: PreviewProvider {
    static func curls() -> Exercise {
        let sets = Sets.maxReps(restSecs: [90, 90, 0])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: [74]))
    }

    static let workout = createWorkout("Strength", [curls()], day: nil).unwrap()

    static var previews: some View {
        EditMaxRepsView(workout: workout, exercise: curls())
    }
}

