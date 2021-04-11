//  Created by Jesse Jones on 12/31/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

//struct AddExerciseView: View {
//    var workout: Workout
//    var exercise: Exercise
//    @State var showHelp = false
//    @State var helpText = ""
//    @ObservedObject var display: Display
//    @Environment(\.presentationMode) private var presentationMode
//    
//    init(_ display: Display, _ workout: Workout) {
//        self.display = display
//        self.workout = workout
//
//        let name = newExerciseName(workout, "Untitled")
//        let modality = Modality(defaultBodyWeight(), defaultRepRanges())
//        self.exercise = Exercise(name, "None", modality)
//
//        self.display.send(.BeginTransaction(name: "add exercise"))
//    }
//    
//    var body: some View {
//        VStack() {
//            Text("Add Exercise" + self.display.edited).font(.largeTitle)
//
//            VStack(alignment: .leading) {
//                HStack {
//                    Menu(getSetsLabel(self.exercise.modality.sets)) {
//                        Button("Durations", action: {self.onChangeSets(defaultDurations())})
//                        Button("Fixed Reps", action: {self.onChangeSets(defaultFixedReps())})
//                        Button("Max Reps", action: {self.onChangeSets(defaultMaxReps())})
//                        Button("Rep Ranges", action: {self.onChangeSets(defaultRepRanges())})
//                        Button("Cancel", action: {})
//                    }.font(.callout).padding(.leading)
//                    Spacer()
//                    Button("?", action: self.onSetsHelp).font(.callout).padding(.trailing)
//                }
//                HStack {
//                    Menu(getApparatusLabel(self.exercise.modality.apparatus)) {
//                        Button("Body Weight", action: {self.onChangeApparatus(defaultBodyWeight())})
//                        Button("Fixed Weights", action: {self.onChangeApparatus(defaultFixedWeights())})
//                        Button("Cancel", action: {})
//                    }.font(.callout).padding(.leading)
//                    Spacer()
//                    Button("?", action: self.onApparatusHelp).font(.callout).padding(.trailing)
//                }
//            }
//            Spacer()
//
//            Divider()
//            HStack {
//                Button("Cancel", action: onCancel).font(.callout)
//                Spacer()
//                Spacer()
//                Button("OK", action: onOK).font(.callout)
//            }
//            .padding()
//        }
//        .alert(isPresented: $showHelp) {   // and views can only have one alert
//            return Alert(
//                title: Text("Help"),
//                message: Text(self.helpText),
//                dismissButton: .default(Text("OK")))
//        }
//    }
//    
//    func onChangeSets(_ sets: Sets) {
//        self.display.send(.SetSets(self.exercise, sets))
//    }
//    
//    func onChangeApparatus(_ apparatus: Apparatus) {
//        self.display.send(.SetApparatus(self.exercise, apparatus))
//    }
//    
//    func onSetsHelp() {
//        self.helpText = getSetsHelp(self.exercise.modality.sets)
//        self.showHelp = true
//    }
//
//    func onApparatusHelp() {
//        self.helpText = getApparatusHelp(self.exercise.modality.apparatus)
//        self.showHelp = true
//    }
//
//    func onCancel() {
//        self.display.send(.RollbackTransaction(name: "add exercise"))
//        self.presentationMode.wrappedValue.dismiss()
//    }
//
//    func onOK() {
//        self.display.send(.AddExercise(workout, self.exercise))
//        self.display.send(.ConfirmTransaction(name: "add exercise"))
//        self.presentationMode.wrappedValue.dismiss()
//    }
//}
//
//struct AddExerciseView_Previews: PreviewProvider {
//    static let display = previewDisplay()
//    static let workout = display.program.workouts[0]
//    
//    static var previews: some View {
//        AddExerciseView(display, workout)
//    }
//}
//
