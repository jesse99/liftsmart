//  Created by Jesse Jones on 12/31/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

func getTypeLabel(_ sets: Sets) -> String {
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

func getTypeHelp(_ sets: Sets) -> String {
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

func defaultDurations(_ name: String, _ apparatus: Apparatus) -> Exercise {
    let durations = [
        DurationSet(secs: 30, restSecs: 60),
        DurationSet(secs: 30, restSecs: 60),
        DurationSet(secs: 30, restSecs: 60)]
    let sets = Sets.durations(durations)
    let modality = Modality(apparatus, sets)
    return Exercise(name, "None", modality)
}

func defaultFixedReps(_ name: String, _ apparatus: Apparatus) -> Exercise {
    let work = RepsSet(reps: RepRange(min: 10, max: 10), restSecs: 30)
    let sets = Sets.fixedReps([work, work, work])
    let modality = Modality(apparatus, sets)
    return Exercise(name, "None", modality)
}

func defaultMaxReps(_ name: String, _ apparatus: Apparatus) -> Exercise {
    let sets = Sets.maxReps(restSecs: [60, 60, 60])
    let modality = Modality(apparatus, sets)
    return Exercise(name, "None", modality)
}

func defaultRepRanges(_ name: String, _ apparatus: Apparatus) -> Exercise {
    let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 120)
    let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
    let modality = Modality(apparatus, sets)
    return Exercise(name, "None", modality)
}

struct AddExerciseView: View {
    var workout: Workout
    let dismiss: () -> Void
    @State var typeLabel = "TypeTypeTypeType"
    @State var apparatusLabel = "ApparatusApparatus"
    @State var type = Sets.repRanges(warmups: [], worksets: [], backoffs: [])
    @State var apparatus = Apparatus.bodyWeight
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
                        Button("Fixed Reps", action: {self.type = .fixedReps([]); self.refresh()})
                        Button("Max Reps", action: {self.type = .maxReps(restSecs: []); self.refresh()})
                        Button("Rep Ranges", action: {self.type = .repRanges(warmups: [], worksets: [], backoffs: []); self.refresh()})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onTypeHelp).font(.callout).padding(.trailing)
                }
                HStack {
                    Menu(self.apparatusLabel) {
                        Button("Body Weight", action: {self.apparatus = .bodyWeight; self.refresh()})
                        Button("Fixed Weights", action: {self.apparatus = .fixedWeights(name: nil); self.refresh()})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onApparatusHelp).font(.callout).padding(.trailing)
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
        self.typeLabel = getTypeLabel(type)
        self.apparatusLabel = getApparatusLabel(apparatus)
    }
    
    func onTypeHelp() {
        self.helpText = getTypeHelp(type)
        self.showHelp = true
    }

    func onApparatusHelp() {
        self.helpText = getApparatusHelp(apparatus)
        self.showHelp = true
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    // TODO: this should do nothing if the sets doesn't change
    // note that that isn't quite an equality check
    func onOK() {
        func findName() -> String {
            let count = workout.exercises.count({$0.name.starts(with: "Untitled ")})
            return "Untitled \(count + 1)"
        }
        
        switch type {
        case .durations(_, targetSecs: _):
            let exercise = defaultDurations(findName(), self.apparatus)
            workout.exercises.append(exercise)
        case .fixedReps(_):
            let exercise = defaultFixedReps(findName(), self.apparatus)
            workout.exercises.append(exercise)
        case .maxReps(restSecs: _, targetReps: _):
            let exercise = defaultMaxReps(findName(), self.apparatus)
            workout.exercises.append(exercise)
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            let exercise = defaultRepRanges(findName(), self.apparatus)
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

