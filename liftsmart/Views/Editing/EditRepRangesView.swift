//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditRepRangesView: View, EditContext {
    let workout: Workout
    var exercise: Exercise
    let original: Exercise
    @State var name = ""
    @State var formalName = ""
    @State var weight = "0.0"
    @State var errText = ""
    @State var errColor = Color.red
    @State var showHelp = false
    @State var helpText = ""
    @State var formalNameModal = false
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, exercise: Exercise) {
        self.workout = workout
        self.exercise = exercise
        self.original = exercise.clone()
    }

    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle)

            VStack(alignment: .leading) {
                createNameView(text: self.$name, self)
                createFormalNameView(text: self.$formalName, modal: self.$formalNameModal, self)
                createWeightView(text: self.$weight, self)
                // TODO: warmups
                // TODO: worksets
                // TODO: backoff
                // apparatus (conditional)
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
//        .modifier(ShowHelp(showing: $showHelp, context: self))
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func refresh() {
        self.name = exercise.name
        self.formalName = exercise.formalName.isEmpty ? "none" : exercise.formalName
        self.weight = String(format: "%.3f", exercise.expected.weight)
        
        switch exercise.modality.sets {
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            break
        default:
            assert(false)
        }
    }
    
    func hasError() -> Bool {
        return !self.errText.isEmpty && self.errColor == .red
    }
            
    func onCancel() {
        self.exercise.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.exercise.name = self.name.trimmingCharacters(in: .whitespaces)
        self.exercise.formalName = self.formalName
        self.exercise.expected.weight = Double(self.weight)!
        
//        exercise.modality.sets = .repRanges(warmups: _, worksets: _, backoffs: _)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepRangesView_Previews: PreviewProvider {
    static func splitSquats() -> Exercise {
        let warmup = RepsSet(reps: RepRange(4)!, percent: WeightPercent(0.0)!, restSecs: 90)!
        let work = RepsSet(reps: RepRange(min: 4, max: 8)!, restSecs: 3*60)!
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }

    static let workout = createWorkout("Strength", [splitSquats()], day: nil).unwrap()

    static var previews: some View {
        EditRepRangesView(workout: workout, exercise: workout.exercises[0])
    }
}

