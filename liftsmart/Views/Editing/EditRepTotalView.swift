//  Created by Jesse Jones on 4/18/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct EditRepTotalView: View {
    let name: String
    let sets: Binding<Sets>
    let expectedReps: Binding<[Int]>
    @State var expected: String
    @State var total: String
    @State var rest: String
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
        case .repTotal(total: let total, rest: let rest):
            self._rest = State(initialValue: restToStr(rest))
            self._total = State(initialValue: "\(total)")
        default:
            self._rest = State(initialValue: "")
            self._total = State(initialValue: "")
            ASSERT(false, "expected repTotal")
        }
    }

    var body: some View {
        VStack() {
            Text("Edit " + self.name + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rest, perform: self.onEditedRest)
                    Button("?", action: self.onRestHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Expected Reps:").font(.headline)
                    TextField("", text: self.$expected)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.expected, perform: self.onEditedExpectedOrTotal)
                    Button("?", action: onExpectedHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Total Reps:").font(.headline)
                    TextField("", text: self.$total)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.total, perform: self.onEditedExpectedOrTotal)
                    Button("?", action: onTotalHelp).font(.callout).padding(.trailing)
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
        .alert(isPresented: $showHelp) {
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func onEditedRest(_ text: String) {
        self.display.send(.ValidateRest(text))
    }
    
    func onEditedExpectedOrTotal(_ text: String) {
        self.display.send(.ValidateRepTotal(self.expected, self.total))
    }
    
    private func onRestHelp() {
        self.helpText = restHelpText
        self.showHelp = true
    }

    func onExpectedHelp() {
        self.helpText = "The number of reps you expect to do for each set. Can be empty."
        self.showHelp = true
    }
        
    func onTotalHelp() {
        self.helpText = "Number of reps to do across arbitrary number of sets."
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

        let total = parseRep(self.total, label: "total").unwrap()
        let rest = parseTimes(self.rest, label: "rest", zeroOK: true).unwrap()[0]
        let msets = Sets.repTotal(total: total, rest: rest)
        if msets != self.sets.wrappedValue {
            self.sets.wrappedValue = msets
        }

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepTotalView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Pullups"})!
    static let sets = Binding.constant(exercise.modality.sets)
    static let expectedReps = Binding.constant(exercise.expected.reps)

    static var previews: some View {
        EditRepTotalView(display, exercise.name, sets, expectedReps)
    }
}

