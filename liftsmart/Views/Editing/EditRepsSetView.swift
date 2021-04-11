//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditRepsSetView: View {
    enum Kind {case Warmup; case WorkSets; case Backoff}

    let workout: Workout
    let exercise: Exercise
    let name: String
    let kind: Kind
    @State var reps: String
    @State var percents: String
    @State var rests: String
    @State var expected: String
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise, _ kind: Kind) {
        self.display = display
        self.workout = workout
        self.exercise = exercise
        self._expected = State(initialValue: " ")

        var sets: [RepsSet] = []
        switch exercise.modality.sets {
        case .repRanges(warmups: let warm, worksets: let work, backoffs: let back):
            switch kind {
            case .Warmup:
                sets = warm
                self.name = "Warmups"
            case .WorkSets:
                sets = work
                self.name = "Work Sets"
                self._expected = State(initialValue: exercise.expected.reps.map({$0.description}).joined(separator: " "))
            case .Backoff:
                sets = back
                self.name = "Backoff"
            }
        default:
            self.name = "?"
            assert(false)
        }
        self.kind = kind

        self._reps = State(initialValue: sets.map({$0.reps.editable}).joined(separator: " "))
        self._percents = State(initialValue: sets.map({$0.percent.editable}).joined(separator: " "))
        self._rests = State(initialValue: sets.map({restToStr($0.restSecs)}).joined(separator: " "))

        self.display.send(.BeginTransaction(name: "change reps sets"))
    }

    var body: some View {
        VStack {
            Text("Edit " + self.name + self.display.edited).font(.largeTitle).font(.largeTitle)
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
        self.display.send(.RollbackTransaction(name: "change reps sets"))
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

        switch self.exercise.modality.sets {
        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            var sets: Sets
            switch self.kind {
            case .Warmup:
                sets = .repRanges(warmups: newSets, worksets: worksets, backoffs: backoffs)
            case .WorkSets:
                sets = .repRanges(warmups: warmups, worksets: newSets, backoffs: backoffs)

                let expected = parseReps(self.expected, label: "expected", emptyOK: true).unwrap()
                if expected != self.exercise.expected.reps {
                    self.display.send(.SetExpectedReps(self.exercise, expected))
                }
            case .Backoff:
                sets = .repRanges(warmups: warmups, worksets: worksets, backoffs: newSets)
            }

            if sets != self.exercise.modality.sets {
                self.display.send(.SetSets(self.exercise, sets))
            }

        default:
            assert(false)
        }

        self.display.send(.ConfirmTransaction(name: "change reps sets"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepsSetView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[1]
    static let exercise = workout.exercises.first(where: {$0.name == "Split Squat"})!

    static var previews: some View {
        Group {
            EditRepsSetView(display, workout, exercise, .WorkSets)
            EditRepsSetView(display, workout, exercise, .Warmup)
        }
    }
}
