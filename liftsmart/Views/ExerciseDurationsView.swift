//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseDurationsView: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    var timer = RestartableTimer(every: TimeInterval.hours(4))
    @State var durations: [DurationSet] = []
    @State var targetSecs: [Int] = []
    @State var title = ""
    @State var subTitle = ""
    @State var startLabel = ""
    @State var noteLabel = ""
    @State var startModal = false
    @State var editModal = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var underway = false
    @Environment(\.presentationMode) private var presentation
    
    init(_ workout: Workout, _ exercise: Exercise, _ history: History) {
        self.workout = workout
        self.exercise = exercise
        self.history = history
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(self.title).font(.title)              // Set 1 of 1
                Text(self.subTitle).font(.headline)        // 60s
                Spacer()

                Button(self.startLabel, action: onStart)
                    .font(.system(size: 40.0))
                    .sheet(isPresented: self.$startModal, onDismiss: self.onStartCompleted) {TimerView(duration: self.startDuration(), secondDuration: self.restSecs())}
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(duration: self.timerDuration())}
                Spacer()
                Text(self.noteLabel).font(.callout)   // Same previous x3
            }

            Divider()
            HStack {
                Button("Reset", action: onReset).font(.callout).disabled(!self.underway)
                Button("History", action: onStartHistory)
                    .font(.callout)
                    .sheet(isPresented: self.$historyModal) {HistoryView(history: self.history, workout: self.workout, exercise: self.exercise)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
                    .sheet(isPresented: self.$noteModal) {NoteView(formalName: self.exercise.formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal, onDismiss: self.refresh) {EditDurationsView(workout: self.workout, exercise: self.exercise)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.onTimer()}
            .onAppear {self.onAppear(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }
    
    func onAppear() {
        if exercise.shouldReset(numSets: durations.count) {
            onReset()
        } else {
            refresh()
        }
    }
    
    func refresh() {
        switch exercise.modality.sets {
        case .durations(let d, targetSecs: let ts):
            self.durations = d
            self.targetSecs = ts
        default:
            assert(false)   // exercise must use durations sets
            self.durations = []
            self.targetSecs = []
        }

        if exercise.current!.setIndex < durations.count {
            self.title = "Set \(exercise.current!.setIndex+1) of \(durations.count)"
        } else if durations.count == 1 {
            self.title = "Finished"
        } else {
            self.title = "Finished all \(durations.count) sets"
        }

        // TODO: If there is an expected weight I think we'd annotate subTitle.
        if exercise.current!.setIndex >= durations.count {
            self.subTitle = ""
        }

        if exercise.current!.setIndex < durations.count {
            let duration = durations[exercise.current!.setIndex]
            if targetSecs.count > 0 {
                let target = targetSecs[exercise.current!.setIndex]
                self.subTitle = "\(duration) (target is \(target)s)"
            } else {
                self.subTitle = "\(duration)"
            }
        } else {
            self.subTitle = ""
        }

        if (exercise.current!.setIndex == durations.count) {
            self.startLabel = "Done"
        } else {
            self.startLabel = "Start"
        }

        self.noteLabel = ""
        if !targetSecs.isEmpty {    // TODO: maybe if have target and progression path
            self.noteLabel = getPreviouslabel(workout, exercise)
        }
    }
    
    func onTimer() {
        if self.exercise.current!.setIndex > 0 {
            self.onReset()
        }
    }
    
    func onReset() {
        self.exercise.current = Current(weight: self.exercise.expected.weight)
        self.underway = false
        self.refresh()
    }
    
    func onNotes() {
        print("Pressed options")  // TODO: implement
    }
    
    func onEdit() {
        self.editModal = true
    }
    
    func onStart() {
        if exercise.current!.setIndex < durations.count {
            self.startModal = true
        } else {
            self.history.append(self.workout, self.exercise)

            let app = UIApplication.shared.delegate as! AppDelegate
            app.saveState()
            
            // Pop this view. Note that currently this only works with a real device, 
            self.presentation.wrappedValue.dismiss()
        }
    }
    
    func onStartCompleted() {
        let duration = durations[exercise.current!.setIndex]
        self.exercise.current!.actualReps.append("\(duration)")
        self.exercise.current!.actualWeights.append("")
        self.exercise.current!.setIndex += 1
        self.underway = self.durations.count > 1
        self.refresh()      // note that dismissing a sheet does not call onAppear
    }
    
    func onStartTimer() {
        self.durationModal = true
    }
    
    func onStartHistory() {
        self.historyModal = true
    }
    
    func onStartNote() {
        self.noteModal = true
    }
    
    func startDuration() -> Int {
        return durations[exercise.current!.setIndex].secs
    }
    
    func timerDuration() -> Int {
        if exercise.current!.setIndex < durations.count {
            return durations[exercise.current!.setIndex].restSecs
        } else {
            return durations.last!.restSecs
        }
    }
    
    func restSecs() -> Int {
        return durations[exercise.current!.setIndex].restSecs
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static let durations = [DurationSet(secs: 60, restSecs: 10), DurationSet(secs: 30, restSecs: 10), DurationSet(secs: 15, restSecs: 10)]
    static let sets = Sets.durations(durations, targetSecs: [90, 60, 30])
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Burpees", "Burpees", modality)
    static let workout = createWorkout("Cardio", [exercise], day: nil).unwrap()

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseDurationsView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
