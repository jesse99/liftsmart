//  Created by Jesse Jones on 4/18/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseRepTargetView: View {
    let workoutIndex: Int
    let exerciseID: Int
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var startTimer = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var editModal = false
    @State var updateExpected = false
    @State var updateRepsDone = false
    @State var underway: Bool
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentation
    
    init(_ display: Display, _ workoutIndex: Int, _ exerciseID: Int) {
        let workout = display.program.workouts[workoutIndex]
        let exercise = workout.exercises.first(where: {$0.id == exerciseID})!
        if exercise.shouldReset() {
            display.send(.ResetCurrent(exercise), updateUI: false)
            display.send(.SetCompleted(exercise, []), updateUI: false)
        }

        self.display = display
        self.workoutIndex = workoutIndex
        self.exerciseID = exerciseID

        self._underway = State(initialValue: exercise.current!.setIndex > 0)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise().name + self.display.edited).font(.largeTitle)   // Curls
                Spacer()
            
                Group {
                    Text(self.getTitle()).font(.title)        // Set 1
                    Text(self.getSubTitle()).font(.headline)  // Expecting 10 reps (20 left)
                    Spacer()
                }

                Button(self.getStartLabel(), action: onNextOrDone)
                    .font(.system(size: 40.0))
                    .actionSheet(isPresented: $updateRepsDone) {
                        ActionSheet(title: Text("Reps Completed"), buttons: repsDoneButtons())}
                    .alert(isPresented: $updateExpected) { () -> Alert in
                        Alert(title: Text("Do you want to updated expected reps?"),
                            primaryButton:   .default(Text("Yes"), action: self.onUpdateExpected),
                            secondaryButton: .default(Text("No"),  action: self.popView))}
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
                    .sheet(isPresented: self.$editModal) {EditExerciseView(self.display, self.workout(), self.exercise())}
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

    func repsDoneButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
                
        if let expected = self.exercise().expected.reps.at(exercise().current!.setIndex) {
            let delta = 4
            for reps in max(expected - delta, 1)...(expected + delta) {
                let str = reps == expected ? "•• \(reps) Reps ••" : "\(reps) Reps"
                let text = Text(str)
                buttons.append(.default(text, action: {() -> Void in self.onRepsPressed(reps)}))
            }
        } else {
            let target = self.getTarget()
            let expected = max(1, target/2)
            for reps in 1...expected {
                let text = Text("\(reps) Reps")
                buttons.append(.default(text, action: {() -> Void in self.onRepsPressed(reps)}))
            }
        }
        
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func onRepsPressed(_ reps: Int) {
        self.display.send(.AppendCurrent(self.exercise(), "\(reps) reps", nil))
        self.startTimer = startDuration(-1) > 0

        let completed = self.exercise().current!.completed + [reps]
        self.display.send(.SetCompleted(self.exercise(), completed))

        self.underway = exercise().current!.setIndex > 0
    }
    
    private func onEdit() {
        self.editModal = true
    }
    
    func onTimer() {
        if self.exercise().current!.setIndex > 0 {
            self.onReset()
        }
    }
    
    func onReset() {
        self.display.send(.ResetCurrent(self.exercise()))
        self.display.send(.SetCompleted(self.exercise(), []))
    }
    
    func onNextOrDone() {
        let target = self.getTarget()
        let completed = self.exercise().current!.completed.reduce(0, {$0 + $1})
        let remaining = completed < target ? target - completed : 0
        if remaining > 0 {
            self.updateRepsDone = true
        } else if self.exercise().current!.completed != self.exercise().expected.reps {
            self.updateRepsDone = false
            self.startTimer = false
            self.updateExpected = true
        } else {
            self.popView()
        }
    }
        
    func onUpdateExpected() {
        let completed = self.exercise().current!.completed
        self.display.send(.SetExpectedReps(self.exercise(), completed))
        
        switch exercise().modality.sets {
        case .repTarget(target: let target, rest: let rest):
            let total = completed.reduce(0, {$0 + $1})
            if total > target {
                let sets = Sets.repTarget(target: total, rest: rest)
                self.display.send(.SetSets(self.exercise(), sets))
            }
        default:
            ASSERT(false, "exercise must use repTarget sets")
        }
        self.popView()
    }

    func popView() {
        self.presentation.wrappedValue.dismiss()
        self.display.send(.AppendHistory(self.workout(), self.exercise()))
        self.display.send(.ResetCurrent(self.exercise()))
    }
    
    func getTimerTitle() -> String {
        if durationModal {
            let target = self.getTarget()
            let completed = self.exercise().current!.completed.reduce(0, {$0 + $1})
            let remaining = completed < target ? target - completed : 0
            if remaining > 0 {
                return "On set \(exercise().current!.setIndex+1)"
            } else {
                return "Finished"
            }
        } else {
            return "Did set \(exercise().current!.setIndex)"
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
        return self.getRestSecs()
    }
    
    func timerDuration() -> Int {
        let secs = self.getRestSecs()
        return secs > 0 ? secs : 60
    }
    
    func getTitle() -> String {
        let completed = self.exercise().current!.completed.reduce(0, {$0 + $1})
        if completed < self.getTarget() {
            return "Set \(exercise().current!.setIndex+1)"
        } else {
            return "Finished"
        }
    }
    
    func getSubTitle() -> String {
        let target = self.getTarget()
        let completed = self.exercise().current!.completed.reduce(0, {$0 + $1})
        let remaining = completed < target ? target - completed : 0
        if let expected = self.exercise().expected.reps.at(exercise().current!.setIndex), expected < remaining {
            return "Expecting \(expected) reps (\(remaining) left)"
        } else if remaining > 0 {
            return "\(remaining) reps left"
        } else {
            return ""
        }
    }

    func getStartLabel() -> String {
        let target = self.getTarget()
        let completed = self.exercise().current!.completed.reduce(0, {$0 + $1})
        let remaining = completed < target ? target - completed : 0
        if remaining == 0 {
            return "Done"
        } else {
            return "Next"
        }
    }
    
    func getNoteLabel() -> String {
        return getPreviouslabel(self.display, workout(), exercise())
    }
    
    private func getTarget() -> Int {
        switch exercise().modality.sets {
        case .repTarget(target: let target, rest: _):
            return target
        default:
            ASSERT(false, "exercise must use repTarget sets")
            return 0
        }
    }

    private func getRestSecs() -> Int {
        switch exercise().modality.sets {
        case .repTarget(target: _, rest: let rest):
            return rest
        default:
            ASSERT(false, "exercise must use repTarget sets") 
            return 0
        }
    }
}

struct ExerciseRepTargetView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex = 0
    static let workout = display.program.workouts[workoutIndex]
    static let exercise = workout.exercises.first(where: {$0.name == "Pullups"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseRepTargetView(display, workoutIndex, exercise.id)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
