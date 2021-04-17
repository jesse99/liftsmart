//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

func getSetsLabel(_ sets: Sets) -> String {
    switch sets {
    case .durations(_, targetSecs: _):
        return "Durations"
    case .fixedReps(_):
        return "Fixed Reps"
    case .maxReps(restSecs: _, targetReps: _):
        return "Max Reps"
    case .repRanges(warmups: _, worksets: _, backoffs: _):
        return "Rep Ranges"
    }
}

func getApparatusLabel(_ apparatus: Apparatus) -> String {
    switch apparatus {
    case .bodyWeight:
        return "Body Weight"
    case .fixedWeights(_):
        return "Fixed Weights"
    }
}

func getSetsHelp(_ sets: Sets) -> String {
    switch sets {
    case .durations(_, targetSecs: _):
        return "Fixed number of sets where each set is done for a time interval."
    case .fixedReps(_):
        return "Fixed number of sets where each set has a fixed number of reps."
    case .maxReps(restSecs: _, targetReps: _):
        return "Fixed number of sets doing as many reps as possible for each set."
    case .repRanges(warmups: _, worksets: _, backoffs: _):
        return "Fixed number of sets where each set has a min and max number of reps with optional warmup and backoff sets."
    }
}

func getApparatusHelp(_ apparatus: Apparatus) -> String {
    switch apparatus {
    case .bodyWeight:
        return "Includes an optional arbitrary weight."
    case .fixedWeights(_):
        return "Dumbbells, kettlebells, cable machines, etc."
    }
}

func defaultBodyWeight() -> Apparatus {
    return .bodyWeight
}

func defaultFixedWeights() -> Apparatus {
    return .fixedWeights(name: nil)
}

func defaultDurations() -> Sets {
    let durations = [
        DurationSet(secs: 30, restSecs: 60),
        DurationSet(secs: 30, restSecs: 60),
        DurationSet(secs: 30, restSecs: 60)]
    return Sets.durations(durations)
}

func defaultFixedReps() -> Sets {
    let work = RepsSet(reps: RepRange(min: 10, max: 10), restSecs: 30)
    return Sets.fixedReps([work, work, work])
}

func defaultMaxReps() -> Sets {
    return Sets.maxReps(restSecs: [60, 60, 60])
}

func defaultRepRanges() -> Sets {
    let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 120)
    return Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
}

// TODO: Wasn't read as true when a State variable.
var editSets = false

struct EditExerciseView: View, ExerciseContext {
    let workout: Workout
    let exercise: Exercise
    @State var name: String
    @State var formalName: String
    @State var weight: String
    @State var sets: Sets
    @State var expectedReps: [Int]
    @State var formalNameModal = false
    @State var editModal = false
    @State var showHelp = false
    @State var helpText = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise) {
        assert(display.program.workouts.first(where: {$0 === workout}) != nil)
        self.display = display
        self.workout = workout
        self.exercise = exercise

        self._name = State(initialValue: exercise.name)
        self._formalName = State(initialValue: exercise.formalName.isEmpty ? "none" : exercise.formalName)
        self._weight = State(initialValue: String(format: "%.3f", exercise.expected.weight))
        self._sets = State(initialValue: exercise.modality.sets)
        self._expectedReps = State(initialValue: exercise.expected.reps)

        self.display.send(.BeginTransaction(name: "change exercise"))
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise" + self.display.edited).font(.largeTitle).padding()

            VStack(alignment: .leading) {
                exerciseNameView(self, self.$name, self.onEditedName)   // TODO: these helpers don't make much sense now
                exerciseFormalNameView(self, self.$formalName, self.$formalNameModal, self.onEditedFormalName)
                exerciseWeightView(self, self.$weight, self.onEditedWeight)
                HStack {
                    Button("Edit", action: self.onEditSets).font(.callout)
                    Spacer()
                    Menu(getSetsLabel(self.sets)) {
                        Button("Durations", action: {self.onChangeSets(defaultDurations())})
                        Button("Fixed Reps", action: {self.onChangeSets(defaultFixedReps())})
                        Button("Max Reps", action: {self.onChangeSets(defaultMaxReps())})
                        Button("Rep Ranges", action: {self.onChangeSets(defaultRepRanges())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onSetsHelp).font(.callout)
                }.padding()
                HStack {
                    Button("Edit", action: self.onEditApparatus)
                        .font(.callout)
                        .disabled(self.exercise.isBodyWeight())
                        .sheet(isPresented: self.$editModal) {
                            if editSets {
                                self.setsView()
                            } else {
                                self.apparatusView()
                            }
                        }
                    Spacer()
                    Menu(getApparatusLabel(self.exercise.modality.apparatus)) {
                        Button("Body Weight", action: {self.onChangeApparatus(defaultBodyWeight())})
                        Button("Fixed Weights", action: {self.onChangeApparatus(defaultFixedWeights())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onApparatusHelp).font(.callout)
                }.padding()
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
    
    private func onEditedName(_ text: String) {
        self.display.send(.ValidateExerciseName(self.workout, self.exercise, text))
    }

    private func onEditedFormalName(_ text: String) {
        self.display.send(.ValidateFormalName(text))    // shouldn't ever fail
    }

    private func onEditedWeight(_ text: String) {
        self.display.send(.ValidateWeight(text, "weight"))
    }
    
    private func onEditSets() {
        editSets = true
        self.editModal = true
    }
    
    private func onEditApparatus() {
        editSets = false
        self.editModal = true
    }
    
    // If we use the normal approach and change the exercise sets then views will be rebuilt
    // and ExerciseView will rebuilt its body which will pop the user back into ExerciseView.
    // This is a bad user experience and can also lead to the user losing associated values
    // in their current sets value so we won't apply the sets changes until they hit OK.
    private func onChangeSets(_ newSets: Sets) {
        if !newSets.sameCase(self.sets) {
            if newSets.sameCase(self.exercise.modality.sets) {
                self.sets = self.exercise.modality.sets // don't lose original associated values
            } else {
                self.sets = newSets
            }
        }
    }
    
    private func onChangeApparatus(_ apparatus: Apparatus) {
        if !apparatus.sameCase(self.exercise.modality.apparatus) {
            self.display.send(.DefaultApparatus(self.workout, self.exercise, apparatus))
        }
    }
    
    private func onSetsHelp() {
        self.helpText = getSetsHelp(self.sets)
        self.showHelp = true
    }

    private func onApparatusHelp() {
        self.helpText = getApparatusHelp(self.exercise.modality.apparatus)
        self.showHelp = true
    }

    private func setsView() -> AnyView {
        switch self.sets {
        case .durations(_, targetSecs: _):
            return AnyView(EditDurationsView(self.display, self.exercise.name, self.$sets))
        case .fixedReps(_):
            return AnyView(EditFixedRepsView(self.display, self.exercise.name, self.$sets))
        case .maxReps(restSecs: _, targetReps: _):
            return AnyView(EditMaxRepsView(self.display, self.exercise.name, self.$sets, self.$expectedReps))
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return AnyView(EditRepRangesView(self.display, self.exercise.name, self.$sets, self.$expectedReps))
        }
    }
    
    private func apparatusView() -> AnyView {
        switch self.exercise.modality.apparatus {
        case .bodyWeight:
            assert(false)
            return AnyView(Text("shouldn't happen"))
        case .fixedWeights(name: _):
            return AnyView(EditFWSsView(self.display, self.exercise))
        }
    }
    
    private func onCancel() {
        self.display.send(.RollbackTransaction(name: "change exercise"))
        self.presentationMode.wrappedValue.dismiss()
    }

    private func onOK() {
        if self.formalName != self.exercise.formalName {
            self.display.send(.SetExerciseFormalName(self.exercise, self.formalName))
        }
        if self.name != self.exercise.name {
            self.display.send(.SetExerciseName(self.workout, self.exercise, self.name))
        }
        
        let weight = Double(self.weight)!
        if weight != self.exercise.expected.weight {
            self.display.send(.SetExpectedWeight(self.exercise, weight))
        }

        if self.expectedReps != self.exercise.expected.reps {
            self.display.send(.SetExpectedReps(self.exercise, self.expectedReps))
        }

        if !self.sets.sameCase(self.exercise.modality.sets) {
            self.display.send(.SetSets(self.exercise, self.sets))
        }

        self.display.send(.ConfirmTransaction(name: "change exercise"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditExerciseView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises.first(where: {$0.name == "Planks"})!

    static var previews: some View {
        EditExerciseView(display, workout, exercise)
    }
}

