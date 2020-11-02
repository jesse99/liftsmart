//  Created by Jesse Jones on 10/23/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditMaxRepsView: View, EditContext {
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
                createNameView(text: self.$name, self)
                createFormalNameView(text: self.$formalName, modal: self.$formalNameModal, self)
                createWeightView(text: self.$weight, self)
                HStack {
                    Text("Reps:").font(.headline)
                    TextField("", text: self.$reps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.reps, perform: self.onEditedReps)
                    Button("?", action: onRepsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                createRestView(text: self.$rest, self)
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
        
    func onRepsHelp() {
        self.helpText = "The number of reps you expect to do across all the sets, e.g. '60'."
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

