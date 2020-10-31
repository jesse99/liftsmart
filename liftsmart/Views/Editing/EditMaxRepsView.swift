//  Created by Jesse Jones on 10/23/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var editMaxRepsID: Int = 0

struct EditMaxRepsView: View {
    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var reps = ""
    @State var target = ""
    @State var rest = ""
    @State var errText = ""
    @State var errColor = Color.red
    @State var showHelp = false
    @State var helpText = ""
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, exercise: Exercise) {
        self.workout = workout
        self.exercise = exercise
        self.original = exercise.clone()
    }

    // TODO:
    // target reps
    // weight (probably need a new view for non-bodyweight apparatus)
    // formal name (will need a new view for this)
    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.name, perform: self.onEditedName)
                    Button("?", action: onNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                // formal name
                // weight
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
                // target reps
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
        self.reps = exercise.expected.reps.isEmpty ? "" : "\(exercise.expected.reps[0])"
        
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
    
    func onEditedName(_ text: String) {
        func isDuplicateName(_ name: String) -> Bool {
            for candidate in self.workout.exercises {
                if candidate !== self.exercise && candidate.name == name {
                    return true
                }
            }
            return false
        }
        
        let name = text.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            self.errText = "Name cannot be empty"
            self.errColor = .red
        } else if isDuplicateName(name) {
            self.errText = "Name matches another exercise in the workout"
            self.errColor = .orange
        } else {
            self.errText = ""
        }
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

    // TODO: Ideally this woule be some sort of markdown popup anchored at the corresponding view.
    func onNameHelp() {
        self.helpText = "Your name for the exercise, e.g. 'Light OHP'."
        self.showHelp = true
    }
    
    func onRepsHelp() {
        self.helpText = "The number of reps you expect to do across all the sets, e.g. '60'."
        self.showHelp = true
    }
    
    func onRestHelp() {
        self.helpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        self.showHelp = true
    }
    
    func onCancel() {
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.exercise.name = self.name.trimmingCharacters(in: .whitespaces)
        self.exercise.expected.reps = self.reps.isEmpty ? [] : [Int(self.reps)!]    // TODO: use isEmptyOrBlank
        
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

