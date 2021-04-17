//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditDurationsView: View, ExerciseContext {
    let name: String
    let sets: Binding<Sets>
    @State var durations: String
    @State var target: String
    @State var rest: String
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String, _ sets: Binding<Sets>) {
        self.display = display
        self.name = name
        self.sets = sets

        switch sets.wrappedValue {
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
    }

    var body: some View {
        VStack() {
            Text("Edit " + self.name + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
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
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let durations = parseTimes(self.durations, label: "durations").unwrap()
        let rest = parseTimes(self.rest, label: "rest", zeroOK: true).unwrap()
        let target = parseTimes(self.target, label: "target").unwrap()
        let sets = zip(durations, rest).map({DurationSet(secs: $0, restSecs: $1)})
        let dsets = Sets.durations(sets, targetSecs: target)
        if dsets != self.sets.wrappedValue {
            self.sets.wrappedValue = dsets
        }

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditDurationsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Planks"})!
    static var sets = Binding.constant(exercise.modality.sets)

    static var previews: some View {
        EditDurationsView(display, exercise.name, sets)
    }
}
