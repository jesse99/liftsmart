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
    let work = RepsSet(reps: RepRange(min: 10, max: 10), restSecs: 30)
    return Sets.fixedReps([work, work, work])
}

func defaultMaxReps() -> Sets {
    return Sets.maxReps(restSecs: [60, 60, 60])
}

func defaultRepRanges() -> Sets {
    let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 120)
    return Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
}

struct AddExerciseView: View {
    var workout: Workout
    @State var typeLabel: String
    @State var apparatusLabel: String
    @State var type: Sets
    @State var apparatus: Apparatus
    @State var showHelp = false
    @State var helpText = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout) {
        self.workout = workout
        self.display = display
        
        let sets = defaultRepRanges()
        self._type = State(initialValue: sets)
        self._typeLabel = State(initialValue: getTypeLabel(sets))
        
        let app = defaultBodyWeight()
        self._apparatus = State(initialValue: app)
        self._apparatusLabel = State(initialValue: getApparatusLabel(app))
        self.display.send(.BeginTransaction(name: "add exercise"))
    }
    
    var body: some View {
        VStack() {
            Text("Add Exercise" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Menu(self.typeLabel) {
                        Button("Durations", action: {self.onChangeType(defaultDurations())})
                        Button("Fixed Reps", action: {self.onChangeType(defaultFixedReps())})
                        Button("Max Reps", action: {self.onChangeType(defaultMaxReps())})
                        Button("Rep Ranges", action: {self.onChangeType(defaultRepRanges())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onTypeHelp).font(.callout).padding(.trailing)
                }
                HStack {
                    Menu(self.apparatusLabel) {
                        Button("Body Weight", action: {self.onChangeApparatus(defaultBodyWeight())})
                        Button("Fixed Weights", action: {self.onChangeApparatus(defaultFixedWeights())})
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
        }
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func onChangeType(_ sets: Sets) {
        self.type = sets
        self.typeLabel = getTypeLabel(sets)
    }
    
    func onChangeApparatus(_ app: Apparatus) {
        self.apparatus = app
        self.apparatusLabel = getApparatusLabel(app)
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
        self.display.send(.RollbackTransaction(name: "add exercise"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.display.send(.AddExercise(self.workout, self.apparatus, self.type))
        self.display.send(.ConfirmTransaction(name: "add exercise"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct AddExerciseView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    
    static var previews: some View {
        AddExerciseView(display, workout)
    }
}

