//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ChangeTypeView: View {
    var workout: Workout
    let index: Int
    let dismiss: () -> Void
    let original: Exercise
    @State var typeLabel = "TypeTypeTypeType"
    @State var type = Sets.repRanges(warmups: [], worksets: [], backoffs: [])
    @State var showHelp = false
    @State var helpText = ""
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, index: Int, dismiss: @escaping () -> Void) {
        self.workout = workout
        self.index = index
        self.dismiss = dismiss
        self.original = workout.exercises[index]
    }
    
    var body: some View {
        VStack() {
            Text("Change Type").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Menu(self.typeLabel) {
                        Button("Durations", action: {self.onChange(.durations([]))})
                        Button("Fixed Reps", action: {self.onChange(.fixedReps([]))})
                        Button("Max Reps", action: {self.onChange(.maxReps(restSecs: []))})
                        Button("Rep Ranges", action: {self.onChange(.repRanges(warmups: [], worksets: [], backoffs: []))})
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
            .onAppear {self.refresh()}
        }
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func refresh() {
        self.type = self.workout.exercises[self.index].modality.sets
        self.typeLabel = getTypeLabel(self.type)
    }
    
    func onChange(_ sets: Sets) {
        func doChange(_ copy: Exercise) {
            let exercise = self.workout.exercises[self.index]
            exercise.modality = Modality(exercise.modality.apparatus, copy.modality.sets)
        }
        
        switch sets {
        case .durations(_, targetSecs: _):
            let copy = defaultDurations("dummy")
            doChange(copy)
        case .fixedReps(_):
            let copy = defaultFixedReps("dummy")
            doChange(copy)
        case .maxReps(restSecs: _, targetReps: _):
            let copy = defaultMaxReps("dummy")
            doChange(copy)
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            let copy = defaultRepRanges("dummy")
            doChange(copy)
        }

        self.refresh()
    }
    
    func onHelp() {
        self.helpText = getTypeHelp(type)
        self.showHelp = true
    }

    func onCancel() {
        self.workout.exercises[self.index].restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.dismiss()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ChangeTypeView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeTypeView(workout: cardio(), index: 0, dismiss: ChangeTypeView_Previews.onDismiss)
    }
    
    static func onDismiss() {
    }
    
    private static func cardio() -> Workout {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        return createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap()
    }
}

