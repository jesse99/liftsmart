//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditExerciseView: View, ExerciseContext {
    let workout: Workout
    let exercise: Exercise
    @State var editModal = false
    @State var editSets = false
    @State var showHelp = false
    @State var helpText = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise) {
        self.display = display
        self.workout = workout
        self.exercise = exercise
        self.display.send(.BeginTransaction(name: "change exercise"))
    }

    var body: some View {
        VStack() {
            Text("Edit " + self.exercise.name + self.display.edited).font(.largeTitle).padding()

            VStack(alignment: .leading) {
                HStack {
                    Button("Edit", action: self.onEditSets).font(.callout)
                    Spacer()
                    Menu(getSetsLabel(self.exercise.modality.sets)) {
                        Button("Durations", action: {self.onChangeSets(defaultDurations())})
                        Button("Fixed Reps", action: {self.onChangeSets(defaultFixedReps())})
                        Button("Max Reps", action: {self.onChangeSets(defaultMaxReps())})
                        Button("Rep Ranges", action: {self.onChangeSets(defaultRepRanges())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onSetsHelp).font(.callout).padding(.trailing)
                }.padding()
                HStack {
                    Button("Edit", action: self.onEditApparatus)
                        .font(.callout)
                        .disabled(self.exercise.isBodyWeight())
                        .sheet(isPresented: self.$editModal) {
                            if self.editSets {
                                self.typeView()
                            } else {
                                self.apparatusView()
                            }}
                    Spacer()
                    Menu(getApparatusLabel(self.exercise.modality.apparatus)) {
                        Button("Body Weight", action: {self.onChangeApparatus(defaultBodyWeight())})
                        Button("Fixed Weights", action: {self.onChangeApparatus(defaultFixedWeights())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onApparatusHelp).font(.callout).padding(.trailing)
                }.padding()
            }
            Spacer()

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
    
    private func onEditSets() {
        self.editModal = true
        self.editSets = true
    }
    
    private func onEditApparatus() {
        self.editModal = true
        self.editSets = false
    }
    
    private func onChangeSets(_ sets: Sets) {
        if !sets.sameCase(self.exercise.modality.sets) {
            self.display.send(.DefaultSets(self.workout, self.exercise, sets))
        }
    }
    
    private func onChangeApparatus(_ apparatus: Apparatus) {
        if !apparatus.sameCase(self.exercise.modality.apparatus) {
            self.display.send(.DefaultApparatus(self.workout, self.exercise, apparatus))
        }
    }
    
    private func onSetsHelp() {
        self.helpText = getSetsHelp(self.exercise.modality.sets)
        self.showHelp = true
    }

    private func onApparatusHelp() {
        self.helpText = getApparatusHelp(self.exercise.modality.apparatus)
        self.showHelp = true
    }

    private func typeView() -> AnyView {
        switch self.exercise.modality.sets {
        case .durations(_, targetSecs: _):
            return AnyView(EditDurationsView(self.display, self.workout, self.exercise))
        case .fixedReps(_):
            return AnyView(EditFixedRepsView(self.display, self.workout, self.exercise))
        case .maxReps(restSecs: _, targetReps: _):
            return AnyView(EditMaxRepsView(self.display, self.workout, self.exercise))
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return AnyView(EditRepRangesView(self.display, self.workout, self.exercise))
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

