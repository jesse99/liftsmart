//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseDurationsView: View {
    let workoutIndex: Int
    let exerciseID: Int
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var underway: Bool
    @State var startModal = false
    @State var editModal = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentation
    
    init(_ display: Display, _ workoutIndex: Int, _ exerciseID: Int) {
        let workout = display.program.workouts[workoutIndex]
        let exercise = workout.exercises.first(where: {$0.id == exerciseID})!
        if exercise.shouldReset() {
            // Note that we have to be careful with state changes within View init methods
            // because init is called multiple times. Here we'll reset current if it's been
            // a really long time or the user earlier finished the exercise.
            display.send(.ResetCurrent(exercise), updateUI: false)
        }

        self.display = display
        self.workoutIndex = workoutIndex
        self.exerciseID = exerciseID
        self._underway = State(initialValue: exercise.current!.setIndex > 0)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise().name + self.display.edited).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(self.getTitle()).font(.title)         // Set 1 of 1
                Text(self.getSubTitle()).font(.headline)   // 60s
                Spacer()

                Button(self.getNextLabel(), action: onNext)
                    .font(.system(size: 40.0))
                    .sheet(isPresented: self.$startModal, onDismiss: self.onNextCompleted) {TimerView(title: self.getTimerTitle(), duration: self.startDuration(), secondDuration: self.restSecs())}
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(title: self.getTimerTitle(), duration: self.timerDuration())}
                Spacer()
                Text(self.getNoteLabel()).font(.callout)   // Same previous x3
            }

            Divider()
            HStack {
                Button("Reset", action: {self.onReset()}).font(.callout).disabled(!self.underway)
                Button("History", action: onStartHistory)
                    .font(.callout)
                    .sheet(isPresented: self.$historyModal) {HistoryView(self.display, self.workoutIndex, self.exerciseID)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
                    .sheet(isPresented: self.$noteModal) {NoteView(self.display, formalName: self.exercise().formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditExerciseView(self.display,  self.workout(), self.exercise())}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.onTimer()}
            .onAppear {self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }
    
    // TODO: Code would be a lot nicer if properties were used but that causes a preview compiler
    // error complaining about missing semi-colon between statements that points to the properties
    // even though they build fine.
    func workout() -> Workout {
        return self.display.program.workouts[workoutIndex]
    }
    
    func exercise() -> Exercise {
        return self.workout().exercises.first(where: {$0.id == self.exerciseID})!
    }
    
//    var workout: Workout {
//        get {return self.display.program.workouts[workoutIndex]}
//    }

//    var exercise: Exercise {
//        get {return self.workout().exercises.first(where: {$0.id == self.exerciseID})!}
//    }

    func onTimer() {
        if self.exercise().current!.setIndex > 0 {
            self.onReset()
        }
    }
    
    func onReset() {
        self.display.send(.ResetCurrent(self.exercise()))
    }
    
    func onEdit() {
        self.editModal = true
    }

    func onNext() {
        let durations = self.durations()
        if exercise().current!.setIndex < durations.count {
            self.startModal = true
        } else {
            self.presentation.wrappedValue.dismiss()
            self.display.send(.AppendHistory(self.workout(), self.exercise()))
            self.display.send(.ResetCurrent(self.exercise()))
        }
    }
    
    func onNextCompleted() {
        let durations = self.durations()
        let duration = durations[exercise().current!.setIndex]
        
        let reps = "\(duration)"
        self.display.send(.AppendCurrent(self.exercise(), reps, nil))
        self.underway = durations.count > 1
    }
    
    func getSetTitle(_ prefix: String) -> String {
        let i = exercise().current!.setIndex
        return "\(prefix) \(i+1) of \(self.exercise().modality.sets.numSets()!)"
    }
    
    func getTimerTitle() -> String {
        assert(display.program.workouts.first(where: {$0 === workout()}) != nil)
        if durationModal {
            let durations = self.durations()
            if exercise().current!.setIndex < durations.count {
                return getSetTitle("On set")
            } else {
                return "Finished"
            }

        } else {
            return getSetTitle("Set")
        }
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
        let durations = self.durations()
        return durations[exercise().current!.setIndex].secs
    }
    
    func timerDuration() -> Int {
        var secs = 0
        let durations = self.durations()
        if exercise().current!.setIndex < durations.count {
            secs = durations[exercise().current!.setIndex].restSecs
        } else {
            secs = durations.last!.restSecs
        }

        return secs > 0 ? secs : 60
    }
    
    func restSecs() -> Int {
        let durations = self.durations()
        return durations[exercise().current!.setIndex].restSecs
    }

    func durations() -> [DurationSet] {
        switch exercise().modality.sets {
        case .durations(let d, targetSecs: _):
            return d
        default:
//            assert(false)   // exercise must use durations sets
            return []
        }
    }
    
    func targetSecs() -> [Int] {
        switch exercise().modality.sets {
        case .durations(_, targetSecs: let target):
            return target
        default:
//            assert(false)   // exercise must use durations sets
            return []
        }
    }
    
    func getTitle() -> String {
        assert(display.program.workouts.first(where: {$0 === workout()}) != nil)
        let durations = self.durations()
        if exercise().current!.setIndex < durations.count {
            return "Set \(exercise().current!.setIndex+1) of \(durations.count)"
        } else if durations.count == 1 {
            return "Finished"
        } else {
            return "Finished all \(durations.count) sets"
        }
    }
    
    func getSubTitle() -> String {
        let durations = self.durations()

        // TODO: If there is an expected weight I think we'd annotate subTitle.
        if exercise().current!.setIndex < durations.count {
            let duration = durations[exercise().current!.setIndex]
            let targetSecs = self.targetSecs()
            if targetSecs.count > 0 {
                let target = targetSecs[exercise().current!.setIndex]
                return "\(duration) (target is \(target)s)"
            } else {
                return "\(duration)"
            }
        } else {
            return ""
        }
    }
    
    func getNextLabel() -> String {
        let durations = self.durations()
        if (exercise().current!.setIndex == durations.count) {
            return "Done"
        } else {
            return "Start"
        }
    }
    
    func getNoteLabel() -> String {
        let targetSecs = self.targetSecs()
        if !targetSecs.isEmpty {    // TODO: maybe if have target and progression path
            return getPreviouslabel(self.display, workout(), exercise())
        } else {
            return ""
        }
    }
}

struct ExerciseDurationsView_Previews2: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex2 = 0
    static let workout2 = display.program.workouts[workoutIndex2]
    static let exercise2 = workout2.exercises.first(where: {$0.name == "Planks"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseDurationsView(display, workoutIndex2, exercise2.id)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
