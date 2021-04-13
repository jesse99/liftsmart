//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct EditFixedRepsView: View, ExerciseContext {
    enum ActiveSheet {case formalName, editReps}

    let workout: Workout
    let exercise: Exercise
    @State var reps: String
    @State var rests: String
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise) {
        self.display = display
        self.workout = workout
        self.exercise = exercise

        switch exercise.modality.sets {
        case .fixedReps(let reps):
            self._reps = State(initialValue: reps.map({$0.reps.editable}).joined(separator: " "))
            self._rests = State(initialValue: reps.map({restToStr($0.restSecs)}).joined(separator: " "))
        default:
            self._reps = State(initialValue: "")
            self._rests = State(initialValue: "")
            assert(false)
        }

        self.display.send(.BeginTransaction(name: "change fixed reps"))
    }

    var body: some View {
        VStack() {
            Text("Edit " + self.exercise.name + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
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
                exerciseRestView(self, self.$rests, self.onEditedSets)
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
    
    func onEditedSets(_ inText: String) {
        self.display.send(.ValidateFixedReps(self.reps, self.rests))
    }
        
    func onRepsHelp() {
        self.helpText = "The number of reps to do for each set."
        self.showHelp = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change fixed reps"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let reps = parseRepRanges(self.reps, label: "reps").unwrap()
        let rest = parseTimes(self.rests, label: "rest", zeroOK: true).unwrap()
        let sets = (0..<reps.count).map({RepsSet(reps: reps[$0], restSecs: rest[$0])})
        let dsets = Sets.fixedReps(sets)
        if dsets != self.exercise.modality.sets {
            self.display.send(.SetSets(self.exercise, dsets))
        }

        self.display.send(.ConfirmTransaction(name: "change fixed reps"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditFixedRepsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Foam Rolling"})!

    static var previews: some View {
        EditFixedRepsView(display, workout, exercise)
    }
}

