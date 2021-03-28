//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditDurationsView: View, EditContext {
    let workout: Workout
    var exercise: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var weight = "0.0"
    @State var durations = ""
    @State var target = ""
    @State var rest = ""
    @State var error = ViewError()
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
        self.display.send(.BeginTransaction(name: "change durations"))
    }

    // TODO:
    // need to validate names
    // how to handle weights validation?
    //    need to verify well-formed and sane
    //    we want display to manage errors so display probably needs to handle it
    //       note that state is often spread across multiple fields
    // handle sets
    var body: some View {
        VStack() {
            Text("Edit Exercise" + self.display.edited).font(.largeTitle)

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
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
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
        return !self.error.isEmpty
    }
    
    func doValidate() {
        func setsMatch() -> Bool {
            // We use zeroOK everywhere because here we only care about the number of elements.
            let count1 = parseTimes(self.durations, label: "durations", zeroOK: true).map(left: {_ in 0}, right: {$0.count})
            let count2 = parseTimes(self.rest, label: "rest", zeroOK: true).map(left: {_ in 0}, right: {$0.count})
            let count3 = parseTimes(self.target, label: "target", zeroOK: true).map(left: {_ in 0}, right: {$0.count})
            return count1 == count2 && (count3 == 0 || count1 == count3)
        }
        
        if setsMatch() {
            self.error.reset(key: "ZGlobal")
        } else {
            self.error.add(key: "ZGlobal", error: "Durations, target, and rest must have the same number of sets (although target can be empty)")
        }
    }
    
    func onEditedDurations(_ text: String) {
        let result = parseTimes(text, label: "durations")
        switch result {
        case .right(let times):
            if !times.isEmpty {
                let rest = parseTimes(self.rest, label: "rest", zeroOK: true)
                if rest.isRight() {
                    updateSets(durs: times, rests: rest.unwrap())
                    doValidate()
                    self.error.reset(key: "Durations")
                }
            } else {
                self.error.add(key: "Durations", error: "Durations needs at least one set")
            }
        case .left(let err):
            self.error.add(key: "Durations", error: err)
        }
    }
    
    func onEditedRest(_ times: [Int]) -> String? {
        let durs = parseTimes(self.durations, label: "durations")   // createRestView will validate rest
        if durs.isRight() {
            updateSets(durs: durs.unwrap(), rests: times)
            doValidate()
        }

        return nil
    }
    
    func onEditedTarget(_ text: String) {
        let result = parseTimes(text, label: "target")
        switch result {
        case .right(let times):
            var sets: [DurationSet]
            switch exercise.modality.sets {
            case .durations(let s, targetSecs: _):
                sets = s
            default:
                assert(false)
                sets = []
            }

            exercise.modality.sets = .durations(sets, targetSecs: times)
            self.error.reset(key: "Target")
            doValidate()
        case .left(let err):
            self.error.add(key: "Target", error: err)
        }
    }
    
    func updateSets(durs: [Int], rests: [Int]) {
        var target: [Int]
        switch exercise.modality.sets {
        case .durations(_, targetSecs: let t):
            target = t
        default:
            assert(false)
            target = []
        }

        let sets = zip(durs, rests).map({DurationSet(secs: $0, restSecs: $1)})
        exercise.modality.sets = .durations(sets, targetSecs: target)
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
        self.display.send(.ConfirmTransaction(name: "change durations"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditDurationsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.last!

    static var previews: some View {
        EditDurationsView(display, workout, exercise)
    }
}

