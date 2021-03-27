//  Created by Jesse Jones on 2/15/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ChangeApparatusView: View {
    var exercise: Exercise
    @State var apparatus: Apparatus
    @State var apparatusLabel: String
    @State var showHelp = false
    @State var helpText = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ exercise: Exercise) {
        self.display = display
        self.exercise = exercise
        self._apparatus = State(initialValue: exercise.modality.apparatus)
        self._apparatusLabel = State(initialValue: getApparatusLabel(exercise.modality.apparatus))
        self.display.send(.BeginTransaction(name: "change apparatus"))
    }
    
    var body: some View {
        VStack() {
            Text("Change Apparatus" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Menu(self.apparatusLabel) {
                        Button("Body Weight", action: {self.onChange(defaultBodyWeight())})
                        Button("Fixed Weights", action: {self.onChange(defaultFixedWeights())})
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
        .alert(isPresented: $showHelp) {  
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
        
    func onChange(_ apparatus: Apparatus) {
        self.apparatus = apparatus
        self.apparatusLabel = getApparatusLabel(self.apparatus)
    }
    
    func onHelp() {
        self.helpText = getApparatusHelp(apparatus)
        self.showHelp = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change apparatus"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        func index(_ apparatus: Apparatus) -> Int {
            switch apparatus {
            case .bodyWeight:
                return 0
            case .fixedWeights(name: _):
                return 1
            }
        }
        
        func matches() -> Bool {
            return index(self.apparatus) == index(self.exercise.modality.apparatus)
        }
        
        if !matches() {
            self.display.send(.ChangeApparatus(self.exercise, self.apparatus))
            self.display.send(.ConfirmTransaction(name: "change apparatus"))
        } else {
            self.display.send(.RollbackTransaction(name: "change apparatus"))
        }
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ChangeApparatusView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    static let exercise = workout.exercises[0]
    
    static var previews: some View {
        ChangeApparatusView(display, exercise)
    }
}

