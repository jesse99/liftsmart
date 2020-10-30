//  Created by Jesse Jones on 10/23/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var editMaxRepsID: Int = 0

struct EditMaxRepsView: View {
    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var errText = ""
    @State var errColor = Color.red
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, exercise: Exercise) {
        self.workout = workout
        self.exercise = exercise
        self.original = exercise.clone()
    }

    // TODO:
    // name
    //    help button, maybe right align this)
    //    remove name from the list of things to do
    // reps (all of these will need help button)
    // rest
    // target reps
    // weight (probably need a new view for non-bodyweight apparatus)
    // formal name (will need a new view for this)
    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.name, perform: self.onEditedName)
                        .padding(.trailing)
                }.padding(.leading)
            }
            Spacer()
            Text(self.errText).foregroundColor(.red).font(.callout).padding(.leading)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.hasError())
            }
            .padding()
            .onAppear {self.refresh()}
        }
    }
    
    func refresh() {
        self.name = exercise.name
    }
    
    func hasError() -> Bool {
        return !self.errText.isEmpty && self.errColor == .red
    }
    
    func onEditedName(_ text: String) {
        func isDuplicateName(_ name: String) -> Bool {
            for candidate in self.workout.exercises {
                if candidate !== self.exercise && candidate.name == name {
                    return true
                }
            }
            return false
        }
        
        let name = text.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            self.errText = "Name cannot be empty"
            self.errColor = .red
        } else if isDuplicateName(name) {
            self.errText = "Name matches another exercise in the workout"
            self.errColor = .orange
        } else {
            self.errText = ""
        }
    }
    
    func onCancel() {
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.exercise.name = self.name.trimmingCharacters(in: .whitespaces)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditMaxRepsView_Previews: PreviewProvider {
    static func curls() -> Exercise {
        let sets = Sets.maxReps(restSecs: [90, 90, 0])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: [74]))
    }

    static let workout = createWorkout("Strength", [curls()], day: nil).unwrap()

    static var previews: some View {
        EditMaxRepsView(workout: workout, exercise: curls())
    }
}

