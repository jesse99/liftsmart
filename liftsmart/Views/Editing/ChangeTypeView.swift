//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ChangeTypeView: View {
    var exercise: Exercise
    let original: Sets
    @State var showHelp = false
    @State var helpText = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ exercise: Exercise) {
        self.display = display
        self.exercise = exercise
        self.original = exercise.modality.sets
        self.display.send(.BeginTransaction(name: "change type"))
    }
    
    var body: some View {
        VStack() {
            Text("Change Type" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Menu(getTypeLabel(self.exercise.modality.sets)) {
                        Button("Durations", action: {self.onChange(defaultDurations())})
                        Button("Fixed Reps", action: {self.onChange(defaultFixedReps())})
                        Button("Max Reps", action: {self.onChange(defaultMaxReps())})
                        Button("Rep Ranges", action: {self.onChange(defaultRepRanges())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onHelp).font(.callout).padding(.trailing)
                }
            }
            Spacer()

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout)
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
    
    func onChange(_ sets: Sets) {
        self.display.send(.SetSets(self.exercise, sets))
    }
    
    func onHelp() {
        self.helpText = getTypeHelp(self.exercise.modality.sets)
        self.showHelp = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change type"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        func index(_ sets: Sets) -> Int {
            switch sets {
            case .durations(_, targetSecs: _):
                return 0
            case .fixedReps(_):
                return 1
            case .maxReps(restSecs: _, targetReps: _):
                return 2
            case .repRanges(warmups: _, worksets: _, backoffs: _):
                return 3
            }
        }
        
        func matches() -> Bool {
            return index(self.original) == index(self.exercise.modality.sets)
        }
        
        if !matches() {
            self.display.send(.ConfirmTransaction(name: "change type"))
        } else {
            // Don't blow away what the user already had.
            self.display.send(.RollbackTransaction(name: "change type"))
        }
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ChangeTypeView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises[0]
    
    static var previews: some View {
        ChangeTypeView(display, exercise)
    }
}

