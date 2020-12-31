//  Created by Jesse Jones on 12/31/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct AddExerciseView: View {
    var workout: Workout
    let dismiss: () -> Void
    @State var typeLabel = "TypeTypeTypeType"
    @State var type = Sets.repRanges(warmups: [], worksets: [], backoffs: [])
    @State var showHelp = false
    @State var helpText = ""
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, dismiss: @escaping () -> Void) {
        self.workout = workout
        self.dismiss = dismiss
    }
    
    var body: some View {
        VStack() {
            Text("Add Exercise").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Menu(self.typeLabel) {
                        Button("Durations", action: {self.type = .durations([]); self.refresh()})
                        Button("Max Reps", action: {self.type = .maxReps(restSecs: []); self.refresh()})
                        Button("Rep Ranges", action: {self.type = .repRanges(warmups: [], worksets: [], backoffs: []); self.refresh()})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onHelp).font(.callout).padding(.trailing)
                }
                // TODO: add a button for apparatus
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
        switch type {
        case .durations(_, targetSecs: _):
            self.typeLabel = "Durations"
        case .maxReps(restSecs: _, targetReps: _):
            self.typeLabel = "Max Reps"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            self.typeLabel = "Rep Ranges"
        }
    }
    
    func onHelp() {
        switch type {
        case .durations(_, targetSecs: _):
            self.helpText = "Fixed number of sets where each set is done for a time interval."
        case .maxReps(restSecs: _, targetReps: _):
            self.helpText = "Fixed number of sets doing as many reps as possible for each set."
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            self.helpText = "Fixed number of sets where each set has a min and max number of reps."
        }
        self.showHelp = true
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        func findName() -> String {
            let count = workout.exercises.count({$0.name.starts(with: "Untitled ")})
            return "Untitled \(count + 1)"
        }
        
        func defaultDurations() -> Exercise {
            let durations = [
                DurationSet(secs: 30, restSecs: 60),
                DurationSet(secs: 30, restSecs: 60),
                DurationSet(secs: 30, restSecs: 60)]
            let sets = Sets.durations(durations)
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise(findName(), "None", modality)
        }
        
        func defaultMaxReps() -> Exercise {
            let sets = Sets.maxReps(restSecs: [60, 60, 60])
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise(findName(), "None", modality)
        }
        
        func defaultRepRanges() -> Exercise {
            let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 120)
            let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise(findName(), "None", modality)
        }
        
        switch type {
        case .durations(_, targetSecs: _):
            let exercise = defaultDurations()
            workout.exercises.append(exercise)
        case .maxReps(restSecs: _, targetReps: _):
            let exercise = defaultMaxReps()
            workout.exercises.append(exercise)
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            let exercise = defaultRepRanges()
            workout.exercises.append(exercise)
        }

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.dismiss()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct AddExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExerciseView(workout: cardio(), dismiss: AddExerciseView_Previews.onDismiss)
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

