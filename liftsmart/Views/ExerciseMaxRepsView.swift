//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseMaxRepsView: View {
    let workoutIndex: Int
    let exerciseID: Int
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var lastReps: Int? = nil // number of reps user did in the last set
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
            display.send(.SetCompleted(exercise, [0]), updateUI: false)
        }

        self.display = display
        self.workoutIndex = workoutIndex
        self.exerciseID = exerciseID

        let count = exercise.modality.sets.numSets()!
        self._underway = State(initialValue: count > 1 && exercise.current!.setIndex > 0)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise().name + self.display.edited).font(.largeTitle)   // Curls
                Spacer()
            
                Group {
                    Text(self.getTitle()).font(.title)              // Set 1 of 1
                    Text(self.getSubTitle()).font(.headline)        // 10+ Reps or As Many Reps As Possible
                    Text(self.getSubSubTitle()).font(.headline)     // Completed 30 reps (target is 90 reps)
                    Spacer()
                }

                Button(self.getStartLabel(), action: onNextOrDone)
                    .font(.system(size: 40.0))
                    .actionSheet(isPresented: $updateRepsDone) {
                        ActionSheet(title: Text("Reps Completed"), buttons: repsDoneButtons())}
                    .alert(isPresented: $updateExpected) { () -> Alert in
                        Alert(title: Text("Do you want to updated expected reps?"),
                            primaryButton: .default(Text("Yes"), action: {
                                let completed = self.exercise().current!.completed.reduce(0, {$0 + $1})
                                self.display.send(.SetExpectedReps(self.exercise(), [completed]))
                                self.popView()}),
                            secondaryButton: .default(Text("No"), action: {
                                self.popView()
                            }))}
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
                
        if let last = self.lastReps {
            let delta = 12  // we'll show +/- this many reps versus expected
            let target = expected() ?? 0
            for reps in max(last - delta, 1)...(last + 2) {
                // TODO: better to use bold() or underline() but they don't do anything
                let str = reps == target ? "•• \(reps) Reps ••" : "\(reps) Reps"
                let text = Text(str)
                buttons.append(.default(text, action: {() -> Void in self.onRepsPressed(reps)}))
            }

        } else if let target = expected() {
            let delta = 10
            for reps in max(target - delta, 1)...(target + delta) {
                let str = reps == target ? "•• \(reps) Reps ••" : "\(reps) Reps"
                let text = Text(str)
                buttons.append(.default(text, action: {() -> Void in self.onRepsPressed(reps)}))
            }
            
        } else {
            for reps in 1...40 {
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

        self.lastReps = reps
        self.underway = self.getRestSecs().count > 1 && exercise().current!.setIndex > 0
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
        self.display.send(.SetCompleted(self.exercise(), [0]))
        self.lastReps = nil
    }
    
    func onNextOrDone() {
        if exercise().current!.setIndex < self.getRestSecs().count {
            self.updateRepsDone = true
        } else if self.exercise().expected.reps.count != 1 || self.exercise().current!.completed[0] != self.exercise().expected.reps.first! {
            self.updateRepsDone = false
            self.startTimer = false
            self.updateExpected = true
        } else {
            self.popView()
        }
    }
    
    func popView() {
        self.presentation.wrappedValue.dismiss()
        self.display.send(.AppendHistory(self.workout(), self.exercise()))
        self.display.send(.ResetCurrent(self.exercise()))
    }
    
    func getTimerTitle() -> String {
        let restSecs = self.getRestSecs()
        if durationModal {
            if exercise().current!.setIndex+1 <= restSecs.count {
                return "On set \(exercise().current!.setIndex+1) of \(restSecs.count)"
            } else {
                return "Finished"
            }
        } else {
            return "Did set \(exercise().current!.setIndex) of \(restSecs.count)"
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
        return self.getRestSecs()[exercise().current!.setIndex + delta]
    }
    
    func timerDuration() -> Int {
        var secs = 0
        let restSecs = self.getRestSecs()
        if exercise().current!.setIndex < restSecs.count {
            secs = restSecs[exercise().current!.setIndex]
        } else {
            secs = restSecs.last!
        }
        
        return secs > 0 ? secs : 60
    }
    
    func expected() -> Int? {
        if let expected = exercise().expected.reps.first, expected > 0 {
            let restSecs = self.getRestSecs()
            if exercise().current!.setIndex < restSecs.count {
                let remaining = Double(expected - (self.exercise().current!.completed.first ?? 0))
                let numSets = Double(restSecs.count - exercise().current!.setIndex)
                let reps = (remaining/numSets).rounded()
                return Int(reps)
            } else {
                return 0
            }
        } else {
            return nil
        }
    }

    func getTitle() -> String {
        let restSecs = self.getRestSecs()
        if exercise().current!.setIndex < restSecs.count {
            return "Set \(exercise().current!.setIndex+1) of \(restSecs.count)"
        } else if restSecs.count == 1 {
            return "Finished"
        } else {
            return "Finished all \(restSecs.count) sets"
        }
    }
    
    func getWeightSuffix() -> Either<String, String> {
        let exercise = self.exercise()
        switch exercise.getClosest(self.display, exercise.expected.weight) {
        case .right(let weight):
            let suffix = weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
            return .right(suffix)
        case .left(let err):
            return .left(err)
        }
    }
        
    func getSubTitle() -> String {
        if exercise().current!.setIndex >= self.getRestSecs().count {
            return  ""
        } else {
            switch self.getWeightSuffix() {
            case .right(let suffix):
                if let target = expected() {
                    return  "\(target)+ reps \(suffix)"
                } else {
                    return  "AMRAP \(suffix)"
                }
            case .left(let err):
                return err
            }
        }
    }
    
    func getSubSubTitle() -> String {
        let restSecs = self.getRestSecs()
        let completed = self.exercise().current!.completed.first ?? 0
        if completed > 0 {
            if let expected = exercise().expected.reps.first {
                if exercise().current!.setIndex < restSecs.count {
                    return "Did \(completed) reps (expecting \(expected) reps)"
                } else if completed == expected {
                    return "Did all \(expected) expected reps"
                } else if completed < expected {
                    return "Missed \(expected - completed) of \(expected) expected reps"
                } else {
                    return "Extra \(completed - expected) of \(expected) expected reps"
                }
            } else {
                return "Did \(completed) reps"
            }

        } else {
            if let expected = exercise().expected.reps.first, expected > 0 {
                if exercise().current!.setIndex < restSecs.count {
                    return "Expecting \(expected) total reps"
                } else {
                    return "Expected \(expected) total reps"
                }
            }
        }
        return ""
    }

    func getStartLabel() -> String {
        if (exercise().current!.setIndex == self.getRestSecs().count) {
            return "Done"
        } else {
            return "Next"
        }
    }
    
    func getNoteLabel() -> String {
        return getPreviouslabel(self.display, workout(), exercise())
    }
    
    private func getRestSecs() -> [Int] {
        switch exercise().modality.sets {
        case .maxReps(let rs, targetReps: _):   // TODO: shouldn't we do something with targetReps? wizard?
            return rs
        default:
//            ASSERT(false)   // exercise must use maxReps sets
            return []
        }
    }
}

struct ExerciseMaxRepsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex = 0
    static let workout = display.program.workouts[workoutIndex]
    static let exercise = workout.exercises.first(where: {$0.name == "Curls"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseMaxRepsView(display, workoutIndex, exercise.id)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
