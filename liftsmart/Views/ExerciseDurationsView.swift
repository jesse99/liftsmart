//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseDurationsView: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    let durations: [DurationSet]
    let targetSecs: [Int]
    @State var startModal: Bool = false
    @State var durationModal: Bool = false
    @State var underway: Bool = false
    @Environment(\.presentationMode) private var presentation
    
    init(_ workout: Workout, _ exercise: Exercise, _ history: History) {
        self.workout = workout
        self.exercise = exercise
        self.history = history

        switch exercise.modality.sets {
        case .durations(let d, targetSecs: let ts):
            self.durations = d
            self.targetSecs = ts
        default:
            assert(false)   // exercise must use durations sets
            self.durations = []
            self.targetSecs = []
        }
        
        self.exercise.initCurrent()
        if self.exercise.current!.setIndex >= self.durations.count {
            // TODO: May just want to come back to the finished state, especially
            // if we have some sort of history view here.
           self.exercise.current!.setIndex = 0
        }
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(title()).font(.title)              // Set 1 of 1
                Text(subTitle()).font(.headline)        // 60s
                Spacer()

                Button(startLabel(), action: onStart)
                    .font(.system(size: 40.0))
                    .sheet(isPresented: self.$startModal, onDismiss: self.onStartCompleted) {TimerView(duration: self.duration(), secondDuration: self.restSecs())}
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(duration: self.duration())}
                Spacer()
            }

            Divider()
            HStack {
                // We have to use underway because body will be updated when a @State var changes
                // but not when some nested field (like exercise.current!.setIndex changes).
                Button("Reset", action: onReset).font(.callout).disabled(!self.underway)
                Spacer()
                // TODO: Do we want a history button? or maybe some sort of details view?
                Button("Notes", action: onNotes).font(.callout)
                Button("Options", action: onOptions).font(.callout)
            }.padding()
        }
    }
    
    func onReset() {
        self.exercise.current!.setIndex = 0
        self.underway = false
    }
    
    func onNotes() {
        print("Pressed options")  // TODO: implement
    }
    
    func onOptions() {
        print("Pressed options")  // TODO: implement
    }
    
    func onStart() {
        if exercise.current!.setIndex < durations.count {
            self.startModal = true
        } else {
            // Pop this view. Note that currently this only works with a real device,
            self.history.append(self.workout, self.exercise)
            self.presentation.wrappedValue.dismiss()
        }
    }
    
    func onStartCompleted() {
        self.exercise.current!.setIndex += 1
        self.underway = self.durations.count > 1
    }
    
    func onStartTimer() {
        self.durationModal = true
    }
    
    func duration() -> Int {
        return durations[exercise.current!.setIndex].secs
    }
    
    func restSecs() -> Int {
        return durations[exercise.current!.setIndex].restSecs
    }
    
    func title() -> String {
        if exercise.current!.setIndex < durations.count {
            return "Set \(exercise.current!.setIndex+1) of \(durations.count)"
        } else if durations.count == 1 {
            return "Finished"
        } else {
            return "Finished all \(durations.count) sets"
        }
    }

    // TODO: If there is an expected weight I think we'd annotate this label.
    func subTitle() -> String {
        if exercise.current!.setIndex >= durations.count {
            return ""
        }

        let duration = durations[exercise.current!.setIndex]
        if targetSecs.count > 0 {
            let target = targetSecs[exercise.current!.setIndex]
            return "\(duration) (target is \(target)s)"
        } else {
            return "\(duration)"
        }
    }
    
    func startLabel() -> String {
        if exercise.current!.setIndex == 0 {
            return "Start"
        } else if (exercise.current!.setIndex == durations.count) {
            return "Done"
        } else {
            return "Next"
        }
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static let durations = [DurationSet(secs: 60, restSecs: 10)!, DurationSet(secs: 30, restSecs: 10)!, DurationSet(secs: 15, restSecs: 10)!]
    static let sets = Sets.durations(durations, targetSecs: [90, 60, 30])
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Burpees", "Burpees", modality)
    static let workout = Workout("Cardio", [exercise])

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseDurationsView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
