//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseFixedRepsView: View {
    let workoutIndex: Int
    let exerciseID: Int
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var startTimer = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var editModal = false
    @State var underway: Bool
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentation
    
    init(_ display: Display, _ workoutIndex: Int, _ exerciseID: Int) {
        let workout = display.program.workouts[workoutIndex]
        let exercise = workout.exercises.first(where: {$0.id == exerciseID})!
        if exercise.shouldReset() {
            display.send(.ResetCurrent(exercise), updateUI: false)
        }

        self.display = display
        self.workoutIndex = workoutIndex
        self.exerciseID = exerciseID

        let count = exercise.modality.sets.numSets()
        self._underway = State(initialValue: count > 1 && exercise.current!.setIndex > 0)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Group {
                    Text(exercise().name + self.display.edited).font(.largeTitle)   // OHP
                    Spacer()
                
                    Text(self.getSetTitle()).font(.title)         // WorkSet 1 of 3
                    Text(self.getPercentTitle()).font(.headline)  // 75% of 120 lbs
                    Spacer().frame(height: 25)

                    Text(self.getRepsTitle()).font(.title)        // 3-5 reps @ 120 lbs
                    Text(self.getPlatesTitle()).font(.headline)   // 25 + 10 + 2.5
                }
                Spacer()

                Button(self.getStartLabel(), action: onNextOrDone)
                    .font(.system(size: 40.0))
                    .sheet(isPresented: self.$startTimer) {TimerView(title: self.getTimerTitle(), duration: self.startDuration(-1))}
                
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(title: self.getTimerTitle(), duration: self.timerDuration())}
                Spacer()
                Text(self.getNoteLabel()).font(.callout)   // Same previous x3
            }

            Divider()
            HStack {
                // We have to use underway because body will be updated when a @State var changes
                // but not when some nested field (like exercise.current!.setIndex changes).
                Button("Reset", action: onReset).font(.callout).disabled(!self.underway)
                Button("History", action: onStartHistory)
                    .font(.callout)
                    .sheet(isPresented: self.$historyModal) {HistoryView(self.display, self.workoutIndex, self.exerciseID)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
                    .sheet(isPresented: self.$noteModal) {NoteView(self.display, formalName: self.exercise().formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditExerciseView(display, self.workout(), self.exercise())}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.onTimer()}
            .onAppear {self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }
    
    func workout() -> Workout {
        return self.display.program.workouts[workoutIndex]
    }
    
    func exercise() -> Exercise {
        return self.workout().exercises.first(where: {$0.id == self.exerciseID})!
    }

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

    func updateReps() {
        let reps = expected()
        let percent = getRepsSet().percent
        self.display.send(.AppendCurrent(self.exercise(), "\(reps) reps", percent.value))

        self.startTimer = startDuration(-1) > 0
        let completed = self.exercise().current!.completed + [reps]
        self.display.send(.SetCompleted(self.exercise(), completed))

        let count = self.getWorkSets().count
        self.underway = count > 1 && exercise().current!.setIndex > 0
    }
    
    func onNextOrDone() {
        if inProgress() {
            updateReps()
        } else {
            self.presentation.wrappedValue.dismiss()

            // Most exercises ask to update expected but for fixedReps there's no real wiggle room
            // so we'll always update it.
            self.display.send(.SetExpectedReps(self.exercise(), self.exercise().current!.completed))
            self.display.send(.AppendHistory(self.workout(), self.exercise()))
            self.display.send(.ResetCurrent(self.exercise()))
        }
    }
    
    private func inProgress() -> Bool {
        return self.exercise().current!.setIndex < self.getWorkSets().count
    }
    
    func getTimerTitle() -> String {
        let worksets = self.getWorkSets()
        if durationModal {
            if exercise().current!.setIndex+1 <= worksets.count {
                return "On set \(exercise().current!.setIndex+1) of \(worksets.count)"
            } else {
                return "Finished"
            }
        } else {
            return "Did set \(exercise().current!.setIndex) of \(worksets.count)"
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
    
    func startDuration(_ delta: Int) -> Int {
        return getRepsSet(delta).restSecs
    }
    
    func timerDuration() -> Int {
        var secs = 0
        let worksets = self.getWorkSets()
        let count = worksets.count
        if exercise().current!.setIndex < count {
            secs = getRepsSet().restSecs
        } else {
            secs = worksets.last!.restSecs
        }
        
        return secs > 0 ? secs : 60
    }
    
    func getStartLabel() -> String {
        if inProgress() {
            return "Next"
        } else {
            return "Done"
        }
    }
    
    func getSetTitle() -> String {
        if inProgress() {
            let i = exercise().current!.setIndex
            return "Workset \(i+1) of \(self.getWorkSets().count)"
        } else {
            return "Finished"
        }
    }
    
    func getPercentTitle() -> String {
        if !exercise().overridePercent.isEmpty {
            return exercise().overridePercent
        } else if inProgress() {
            let percent = getRepsSet().percent
            let display = percent.value >= 0.01 && percent.value <= 0.99
            return display ? "\(percent.label) of \(exercise().expected.weight) lbs" : ""
        } else {
            return ""
        }
    }
    
    func getRepsTitle() -> String {
        var title = ""
        if inProgress() {
            let percent = getRepsSet().percent
            let weight = exercise().expected.weight * percent
            
            let reps = expected()
            title = reps == 1 ? "1 rep" : "\(reps) reps"
            title += percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
        }
        return title
    }
    
    func getPlatesTitle() -> String {
        return ""        // TODO: needs to use apparatus
    }
    
    func getNoteLabel() -> String {
        func shouldTrackHistory() -> Bool {
            // TODO: also true if apparatus is barbell, dumbbell, or machine
            let worksets = self.getWorkSets()
            if let reps = worksets.first?.reps, reps.min < reps.max {
                return true
            }
            return false
        }
        
        if shouldTrackHistory() {
            return getPreviouslabel(self.display, workout(), exercise())
        } else {
            return ""
        }
    }

    private func getRepsSet(_ delta: Int = 0) -> RepsSet {
        let i = self.exercise().current!.setIndex + delta

        let worksets = self.getWorkSets()
        if i < worksets.count {
            return worksets[i]
        }

//        assert(false)
        return RepsSet(reps: RepRange(5))
    }

    private func expected() -> Int {
        if inProgress() {
            let i = self.exercise().current!.setIndex
            return self.exercise().expected.reps.at(i) ?? getRepsSet().reps.min
        } else {
            return getRepsSet().reps.min
        }
    }
    
    private func getWorkSets() -> [RepsSet] {
        switch exercise().modality.sets {
        case .fixedReps(let ws):
            return ws
        default:
//            assert(false)   // this exercise must use fixedReps sets
            return []
        }
    }
}

struct ExerciseFixedRepsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex = 0
    static let workout = display.program.workouts[workoutIndex]
    static let exercise = workout.exercises.first(where: {$0.name == "Foam Rolling"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseFixedRepsView(display, workoutIndex, exercise.id)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
