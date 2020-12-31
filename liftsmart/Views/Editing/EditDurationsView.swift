//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditDurationsView: View, EditContext {
    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var weight = "0.0"
    @State var durations = ""
    @State var target = ""
    @State var rest = ""
    @State var errText = ""
    @State var errColor = Color.red   // this is required by EditContext
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
                    Text("Durations:").font(.headline)
                    TextField("", text: self.$durations)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.durations, perform: self.onEditedDurations)
                    Button("?", action: self.onDurationsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Target:").font(.headline)
                    TextField("", text: self.$target)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.target, perform: self.onEditedTarget)
                    Button("?", action: self.onTargetHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                createRestView(text: self.$rest, self, extra: self.onEditedRest)
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
        self.weight = String(format: "%.3f", exercise.expected.weight)
        
        switch exercise.modality.sets {
        case .durations(let d, targetSecs: let t):
            self.durations = d.map({restToStr($0.secs)}).joined(separator: " ")
            self.rest = d.map({restToStr($0.restSecs)}).joined(separator: " ")
            self.target = t.map({restToStr($0)}).joined(separator: " ")
        default:
            assert(false)
        }
    }
    
    func hasError() -> Bool {
        return !self.errText.isEmpty && self.errColor == .red
    }
    
    func setsMatch() -> Bool {
        let count1 = self.durations.split(separator: " ").count
        let count2 = self.rest.split(separator: " ").count
        let count3 = self.target.split(separator: " ").count
        return count1 == count2 && (count3 == 0 || count1 == count3)
    }
    
    func validateSecs(_ text: String, label: String) {
        if !setsMatch() {
            self.errText = "Durations, target, and rest must have the same number of sets (although target can be empty)"
            self.errColor = .red
            return
        }
        
        for token in text.split(separator: " ") {
            switch strToDuration(String(token), label: label) {
            case .right(_):
                self.errText = ""
            case .left(let err):
                self.errText = err
                self.errColor = .red
                return
            }
        }
    }
    
    func onEditedDurations(_ inText: String) {
        let text = inText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            self.errText = "Durations needs at least one set"
            self.errColor = .red
            return       // bail on the first error
        }
        
        validateSecs(text, label: "duration")
        if self.errText.isEmpty {
            updateSets(durs: text, rests: self.rest)
        }
    }
    
    func onEditedRest(_ text: String) -> String? {
        if !setsMatch() {
            return "Durations, target, and rest must have the same number of sets (although target can be empty)"
        }
        if self.errText.isEmpty {
            updateSets(durs: self.durations, rests: text)
        }
        return nil
    }
    
    func updateSets(durs: String, rests: String) {
        var target: [Int]
        switch exercise.modality.sets {
        case .durations(_, targetSecs: let t):
            target = t
        default:
            assert(false)
            target = []
        }

        let secs = durs.split(separator: " ").map({strToRest(String($0)).unwrap()})
        let restSecs = rests.split(separator: " ").map({strToRest(String($0)).unwrap()})
        let sets = zip(secs, restSecs).map({DurationSet(secs: $0, restSecs: $1)})
        exercise.modality.sets = .durations(sets, targetSecs: target)
    }

    func onEditedTarget(_ inText: String) {
        let text = inText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            self.errText = ""
            return       // OK to have no target
        }
        
        validateSecs(text, label: "target")
        
        if self.errText.isEmpty {
            var sets: [DurationSet]
            switch exercise.modality.sets {
            case .durations(let s, targetSecs: nil):
                sets = s
            default:
                assert(false)
                sets = []
            }

            let targ = text.split(separator: " ").map({strToRest(String($0)).unwrap()})
            exercise.modality.sets = .durations(sets, targetSecs: targ)
        }
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
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditDurationsView_Previews: PreviewProvider {
    static func burpees() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 45, restSecs: 60)])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Burpees", "Burpees", modality)
    }

    static let workout = createWorkout("Cardio", [burpees()], day: nil).unwrap()

    static var previews: some View {
        EditDurationsView(workout: workout, exercise: workout.exercises[0])
    }
}

