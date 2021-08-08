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
    case .repTotal(total: _, rest: _):
        return "Rep Total"
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
        return "Each set is done for a time interval."
    case .fixedReps(_):
        return "Sets and reps are both fixed. No support for weight percentages."
    case .maxReps(restSecs: _, targetReps: _):
        return "As many reps as possible for each set."
    case .repRanges(warmups: _, worksets: _, backoffs: _):
        return "Has optional warmup and backoff sets. Reps are within a specified range and weight percentages can be used."
    case .repTotal(total: _, rest: _):
        return "As many sets as required to do total reps."
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
    let work = FixedRepsSet(reps: FixedReps(10), restSecs: 30)
    return Sets.fixedReps([work, work, work])
}

func defaultMaxReps() -> Sets {
    return Sets.maxReps(restSecs: [60, 60, 60])
}

func defaultRepRanges() -> Sets {
    let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 120)
    return Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
}

func defaultRepTotal() -> Sets {
    return Sets.repTotal(total: 15, rest: 60)
}

// TODO: Wasn't read as true when a State variable. Likely because of the way state variables
// get unplugged from the state store, see https://nalexn.github.io/stranger-things-swiftui-state.
var editSets = false

struct EditExerciseView: View {
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
        ASSERT(display.program.workouts.first(where: {$0 === workout}) != nil, "didn't find workout")
        self.display = display
        self.workout = workout
        self.exercise = exercise

        self._name = State(initialValue: exercise.name)
        self._formalName = State(initialValue: exercise.formalName.isEmpty ? "none" : exercise.formalName)
        self._weight = State(initialValue: friendlyWeight(exercise.expected.weight))
        self._sets = State(initialValue: exercise.modality.sets)
        self._expectedReps = State(initialValue: exercise.expected.reps)

        self.display.send(.BeginTransaction(name: "change exercise"))
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise" + self.display.edited).font(.largeTitle).padding()

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .autocapitalization(.words)
                        .onChange(of: self.name, perform: self.onEditedName)
                    Button("?", action: self.onNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)

                HStack {
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {self.formalNameModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$formalNameModal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: self.onEditedFormalName)}
                    Spacer()
                    Button("?", action: self.onFormalNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)

                // Probably want to handle weight differently for different apparatus. For example, for barbell
                // could use a picker like formal name uses: user can type in a weight and then is able to see
                // all the nearby weights and select one if he wants.
                HStack {
                    Text("Weight:").font(.headline)
                    TextField("", text: self.$weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .onChange(of: self.weight, perform: self.onEditedWeight)
                    Button("?", action: self.onWeightHelp).font(.callout).padding(.trailing)
                }.padding(.leading)

                HStack {
                    Button("Edit", action: self.onEditSets).font(.callout)
                    Spacer()
                    Menu(getSetsLabel(self.sets)) {
                        Button("Durations", action: {self.onChangeSets(defaultDurations())})
                        Button("Fixed Reps", action: {self.onChangeSets(defaultFixedReps())})
                        Button("Max Reps", action: {self.onChangeSets(defaultMaxReps())})
                        Button("Rep Ranges", action: {self.onChangeSets(defaultRepRanges())})
                        Button("Rep Total", action: {self.onChangeSets(defaultRepTotal())})
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
        self.formalName = text
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
    
    private func matchFormalName(_ inText: String) -> [String] {
        var names: [String] = []
        
        // TODO: better to do a proper fuzzy search
        let needle = inText.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()

        // First match any custom names defined by the user.
        for candidate in self.display.userNotes.keys {
            if defaultNotes[candidate] == nil {
                let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
                if haystack.contains(needle) {
                    names.append(candidate)
                }
            }
        }
        
        // Then match the standard names.
        for candidate in defaultNotes.keys {
            let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
            if haystack.contains(needle) {
                names.append(candidate)
            }
            
            // Not much point in showing the user a huge list of names.
            if names.count >= 100 {
                break
            }
        }

        return names
    }

    // If we use the normal approach and change the exercise sets then views will be rebuilt
    // and ExerciseView will rebuilt its body which will pop the user back into ExerciseView.
    // This is a bad user experience and can also lead to the user losing associated values
    // in their current sets value so we won't apply the sets changes until they hit OK.
    private func onChangeSets(_ newSets: Sets) {
        if !newSets.sameCase(self.sets) {
            if newSets.sameCase(self.exercise.modality.sets) {
                self.sets = self.exercise.modality.sets // don't lose original associated values
                self.expectedReps = exercise.expected.reps
            } else {
                self.sets = newSets
                self.expectedReps = []  // TODO: reset expected weight too?
            }
        }
    }
    
    private func onChangeApparatus(_ apparatus: Apparatus) {
        if !apparatus.sameCase(self.exercise.modality.apparatus) {
            self.display.send(.DefaultApparatus(self.workout, self.exercise, apparatus))
            self.expectedReps = []  // TODO: reset expected weight too?
        }
    }
    
    private func onSetsHelp() {
        self.helpText = getSetsHelp(self.sets)
        self.showHelp = true
    }

    private func onNameHelp() {
        self.helpText = "Your name for the exercise, e.g. 'Light OHP'."
        self.showHelp = true
    }

    private func onFormalNameHelp() {
        self.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
        self.showHelp = true
    }

    private func onWeightHelp() {
        self.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
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
            return AnyView(EditFixedRepsView(self.display, self.exercise.name, self.$sets, self.$expectedReps))
        case .maxReps(restSecs: _, targetReps: _):
            return AnyView(EditMaxRepsView(self.display, self.exercise.name, self.$sets, self.$expectedReps))
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return AnyView(EditRepRangesView(self.display, self.exercise.name, self.$sets, self.$expectedReps))
        case .repTotal(total: _, rest: _):
            return AnyView(EditRepTotalView(self.display, self.exercise.name, self.$sets, self.$expectedReps))
        }
    }
    
    private func apparatusView() -> AnyView {
        switch self.exercise.modality.apparatus {
        case .bodyWeight:
            ASSERT(false, "expected bodyweight")
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

        if self.sets != self.exercise.modality.sets {
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

