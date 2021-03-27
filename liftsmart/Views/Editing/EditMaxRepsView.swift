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
    @State var error = ViewError()
    @State var errMesg = ""
    @State var errColor = Color.black
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
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
                createFormalNameView(text: self.$formalName, modal: self.$formalNameModal, self)
                createWeightView(text: self.$weight, self)
                createRestView(text: self.$rest, self)
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
        return !self.error.isEmpty
    }
    
    func onEditedReps(_ text: String) {
        switch parseOptionalRep(text, label: "reps") {
        case .right(let r):
            self.error.reset(key: "Reps")
            if let reps = r {
                self.exercise.expected.reps = [reps]
            } else {
                self.exercise.expected.reps = []
            }

        case .left(let err):
            self.error.add(key: "Reps", error: err)
        }
    }
    
    func onEditedTarget(_ text: String) {
        var rest: [Int]
        switch exercise.modality.sets {
        case .maxReps(restSecs: let r, targetReps: _):
            rest = r
        default:
            assert(false)
            rest = []
        }

        switch parseOptionalRep(text, label: "target") {
        case .right(let reps):
            self.error.reset(key: "Target")
            self.exercise.modality.sets = .maxReps(restSecs: rest, targetReps: reps)

        case .left(let err):
            self.error.add(key: "Target", error: err)
        }
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
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {        
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
        EditMaxRepsView(workout: workout, exercise: workout.exercises[0])
    }
}

