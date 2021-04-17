//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct EditFixedRepsView: View {
    enum ActiveSheet {case formalName, editReps}

    let name: String
    let sets: Binding<Sets>
    @State var reps: String
    @State var rests: String
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
        case .fixedReps(let reps):
            self._reps = State(initialValue: reps.map({$0.reps.editable}).joined(separator: " "))
            self._rests = State(initialValue: reps.map({restToStr($0.restSecs)}).joined(separator: " "))
        default:
            self._reps = State(initialValue: "")
            self._rests = State(initialValue: "")
            assert(false)
        }
    }

    var body: some View {
        VStack() {
            Text("Edit " + self.name + self.display.edited).font(.largeTitle)

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
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rests)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rests, perform: self.onEditedSets)
                    Button("?", action: self.onResttHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
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

    private func onResttHelp() {
        self.helpText = restHelpText
        self.showHelp = true
    }

    func onRepsHelp() {
        self.helpText = "The number of reps to do for each set."
        self.showHelp = true
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let reps = parseRepRanges(self.reps, label: "reps").unwrap()
        let rest = parseTimes(self.rests, label: "rest", zeroOK: true).unwrap()
        let sets = (0..<reps.count).map({RepsSet(reps: reps[$0], restSecs: rest[$0])})
        let dsets = Sets.fixedReps(sets)
        if dsets != self.sets.wrappedValue {
            self.sets.wrappedValue = dsets
        }

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditFixedRepsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Foam Rolling"})!
    static var sets = Binding.constant(exercise.modality.sets)

    static var previews: some View {
        EditFixedRepsView(display, exercise.name, sets)
    }
}

