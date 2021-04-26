//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct EditFixedRepsView: View {
    enum ActiveSheet {case formalName, editReps}

    let name: String
    let sets: Binding<Sets>
    let expectedReps: Binding<[Int]>
    @State var expected: String
    @State var reps: String
    @State var rests: String
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String, _ sets: Binding<Sets>, _ expectedReps: Binding<[Int]>) {
        self.display = display
        self.name = name
        self.sets = sets
        self.expectedReps = expectedReps

        let reps = expectedReps.wrappedValue.map {"\($0)"}
        self._expected = State(initialValue: reps.joined(separator: " "))

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
                    Text("Expected Reps:").font(.headline)
                    TextField("", text: self.$expected)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.expected, perform: self.onEditedExpected)
                    Button("?", action: onExpectedHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rests)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rests, perform: self.onEditedSets)
                    Button("?", action: self.onRestHelp).font(.callout).padding(.trailing)
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

    func onEditedExpected(_ text: String) {
        // TODO: complain if expected sum > target?
        self.display.send(.ValidateExpectedRepList(text))
    }
    
    func onExpectedHelp() {
        self.helpText = "The number of reps you expect to do for each set. Can be empty."
        self.showHelp = true
    }

    private func onRestHelp() {
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
        let expected = parseReps(self.expected, label: "expected", emptyOK: true).unwrap()
        if expected != self.expectedReps.wrappedValue {
            self.expectedReps.wrappedValue = expected
        }

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
    static let expectedReps = Binding.constant(exercise.expected.reps)

    static var previews: some View {
        EditFixedRepsView(display, exercise.name, sets, expectedReps)
    }
}

