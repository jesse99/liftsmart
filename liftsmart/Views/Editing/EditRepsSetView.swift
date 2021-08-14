//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

func extJoin(_ values: [String]) -> String {
    if values.count > 1 && values.all({$0 == values[0]}) {
        return values[0] + " x\(values.count)"
    } else {
        return values.joined(separator: " ")
    }
}

struct EditRepsSetView: View {
    enum Kind {case Warmup; case WorkSets; case Backoff}

    let name: String
    let sets: Binding<Sets>
    let expectedReps: Binding<[Int]>
    let setsName: String
    let kind: Kind
    @State var reps: String
    @State var percents: String
    @State var rests: String
    @State var expected: String
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String, _ kind: Kind, _ sets: Binding<Sets>, _ expectedReps: Binding<[Int]>) {
        self.display = display
        self.name = name
        self.sets = sets
        self.expectedReps = expectedReps
        self._expected = State(initialValue: " ")

        var newSets: [RepsSet] = []
        switch sets.wrappedValue {
        case .repRanges(warmups: let warm, worksets: let work, backoffs: let back):
            switch kind {
            case .Warmup:
                newSets = warm
                self.setsName = "Warmups"
            case .WorkSets:
                newSets = work
                self.setsName = "Work Sets"
                self._expected = State(initialValue: extJoin(expectedReps.wrappedValue.map({$0.description})))
            case .Backoff:
                newSets = back
                self.setsName = "Backoff"
            }
        default:
            self.setsName = "?"
            ASSERT(false, "expected repRanges")
        }
        self.kind = kind

        self._reps = State(initialValue: extJoin(newSets.map({$0.reps.editable})))
        self._percents = State(initialValue: extJoin(newSets.map({$0.percent.editable})))
        self._rests = State(initialValue: extJoin(newSets.map({restToStr($0.restSecs)})))
    }
    
    var body: some View {
        VStack {
            Text("\(self.name) \(self.setsName)\(self.display.edited)").font(.largeTitle).font(.largeTitle)
            HStack {
                Text("Reps:").font(.headline)
                TextField("", text: self.$reps)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .onChange(of: self.reps, perform: self.onEditedSets)
                    .padding()
            }.padding(.leading)
            HStack {
                Text("Percents:").font(.headline)
                TextField("", text: self.$percents)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .onChange(of: self.percents, perform: self.onEditedSets)
                    .padding()
            }.padding(.leading)
            HStack {
                Text("Rest:").font(.headline)
                TextField("", text: self.$rests)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .onChange(of: self.rests, perform: self.onEditedSets)
                    .padding()
            }.padding(.leading)
            if case .WorkSets = self.kind {
                HStack {
                    Text("Expected:").font(.headline)
                    TextField("", text: self.$expected)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.expected, perform: self.onEditedSets)
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
            }.padding()
        }
    }
    
    func onEditedSets(_ text: String) {
        switch self.kind {
        case .WorkSets:
            self.display.send(.ValidateRepRanges(self.reps, self.percents, self.rests, self.expected))
        default:
            self.display.send(.ValidateRepRanges(self.reps, self.percents, self.rests, nil))
        }
    }
    
    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        var newSets: [RepsSet] = []
        let reps = parseRepRanges(self.reps, label: "reps").unwrap()
        let percent = parsePercents(self.percents, label: "percents").unwrap()
        let rest = parseTimes(self.rests, label: "rest", zeroOK: true).unwrap()
        for i in 0..<reps.count {
            newSets.append(RepsSet(reps: reps[i], percent: percent[i], restSecs: rest[i]))
        }

        switch self.sets.wrappedValue {
        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            var sets: Sets
            switch self.kind {
            case .Warmup:
                sets = .repRanges(warmups: newSets, worksets: worksets, backoffs: backoffs)
            case .WorkSets:
                sets = .repRanges(warmups: warmups, worksets: newSets, backoffs: backoffs)

                let expected = parseReps(self.expected, label: "expected", emptyOK: true).unwrap()
                if expected != self.expectedReps.wrappedValue {
                    self.expectedReps.wrappedValue = expected
                }
            case .Backoff:
                sets = .repRanges(warmups: warmups, worksets: worksets, backoffs: newSets)
            }

            if sets != self.sets.wrappedValue {
                self.sets.wrappedValue = sets
            }

        default:
            ASSERT(false, "expected repRanges")
        }

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepsSetView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[1]
    static let exercise = workout.exercises.first(where: {$0.name == "Split Squat"})!
    static let sets = Binding.constant(exercise.modality.sets)
    static let expectedReps = Binding.constant(exercise.expected.reps)

    static var previews: some View {
        Group {
            EditRepsSetView(display, exercise.name, .WorkSets, sets, expectedReps)
            EditRepsSetView(display, exercise.name, .Warmup, sets, expectedReps)
        }
    }
}
