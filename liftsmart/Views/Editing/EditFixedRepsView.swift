//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct EditFixedRepsView: View, EditContext {
    enum ActiveSheet {case formalName, editReps}

    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var weight = "0.0"
    @State var reps = ""
    @State var rests = ""
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
                HStack {        // better to use createFormalNameView but that doesn't quite work with multiple sheets
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {sheetAction = .formalName; self.formalNameModal = true})
                        .font(.callout)
                    Spacer()
                    Button("?", action: {formalNameHelp(self)}).font(.callout).padding(.trailing)
                }.padding(.leading)
                createWeightView(text: self.$weight, self)
                HStack {
                    Text("Reps:").font(.headline)
                    TextField("", text: self.$reps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.reps, perform: self.onEditedSets)
                        .padding()
                    Button("?", action: onRepsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rests)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rests, perform: self.onEditedSets)
                        .padding()
                    Button("?", action: onRestHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                // apparatus (conditional)
            }
            .sheet(isPresented: self.$formalNameModal) {
                PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: {editedFormalName($0, self)})
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
        self.weight = String(format: "%.3f", exercise.expected.weight)

        var repsSet = [RepsSet(reps: RepRange(10))]
        switch exercise.modality.sets {
        case .fixedReps(let s):
            repsSet = s
        default:
            assert(false)
        }
        self.reps = repsSet.map({$0.reps.editable}).joined(separator: " ")
        self.rests = repsSet.map({restToStr($0.restSecs)}).joined(separator: " ")
    }
    
    func doValidate() -> [RepsSet]? {
        // Check each rep
        var newReps: [RepRange] = []
        switch parseRepRanges(self.reps, label: "reps") {
        case .right(let reps):
            newReps = reps
        case .left(let err):
            self.error.add(key: "ZGlobal", error: err)
            return nil
        }

        // Check each rest
        var newRest: [Int] = []
        switch parseTimes(self.rests, label: "rest", zeroOK: true) {
        case .right(let times):
            newRest = times
        case .left(let err):
            self.error.add(key: "ZGlobal", error: err)
            return nil
        }
        
        // Ensure that counts match up
        if newReps.count == newRest.count {
            var newSets: [RepsSet] = []
            for i in 0..<newReps.count {
                newSets.append(RepsSet(reps: newReps[i], restSecs: newRest[i]))
            }
            self.error.reset(key: "ZGlobal")
            return newSets

        } else {
            self.error.add(key: "ZGlobal", error: "Reps and rest counts must match")
            return nil
        }
    }
    
    func onEditedSets(_ inText: String) {
        if let newSets = doValidate() {
            self.exercise.modality.sets = .fixedReps(newSets)
            self.exercise.expected.reps = newSets.map({$0.reps.min})
        }
    }
        
    func onRepsHelp() {
        self.helpText = "The number of reps to do for each set."
        self.showHelp = true
    }

    func onRestHelp() {
        self.helpText = "The amount of time to rest after each set."
        self.showHelp = true
    }

    func hasError() -> Bool {
        return !self.error.isEmpty
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

struct EditFixedRepsView_Previews: PreviewProvider {
    static func splitSquats() -> Exercise {
        let work = RepsSet(reps: RepRange(8), restSecs: 60)
        let sets = Sets.fixedReps([work, work, work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Mountain Climber", "Mountain Climber", modality, Expected(weight: 5.0, reps: [8, 8, 8]))
    }

    static let workout = createWorkout("Strength", [splitSquats()], day: nil).unwrap()

    static var previews: some View {
        EditFixedRepsView(workout: workout, exercise: workout.exercises[0])
    }
}

