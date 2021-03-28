//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

func getPreviouslabel(_ workout: Workout, _ exercise: Exercise) -> String {
    var count = 0
    var actual = ""
    for record in historyX.exercise(workout, exercise).reversed() {
        if actual.isEmpty {
            if record.label.isEmpty {
                break
            }
            actual = record.label
            count = 1
        } else if record.label == actual {
            count += 1
        } else {
            break
        }
    }
    return count > 0 ? "Same previous x\(count)" : ""
}

struct ExerciseRepRangesView: View {
    let workout: Workout
    let exercise: Exercise
    let warmups: [RepsSet]
    let worksets: [RepsSet]
    let backoffs: [RepsSet]
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var completed: [Int] = []  // number of reps the user has done so far (not counting warmup)
    @State var startTimer = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var apparatusModal = false
    @State var editModal = false
    @State var updateExpected = false
    @State var updateRepsDone = false
    @State var underway: Bool
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentation
    
    init(_ display: Display, _ workout: Workout, _ exercise: Exercise) {
        if exercise.shouldReset() {
            display.send(.ResetCurrent(exercise), updateUI: false)
        }

        self.display = display
        self.workout = workout
        self.exercise = exercise

        switch exercise.modality.sets {
        case .repRanges(warmups: let wu, worksets: let ws, backoffs: let bo):
            self.warmups = wu
            self.worksets = ws
            self.backoffs = bo
        default:
            assert(false)   // this exercise must use repRanges sets
            self.warmups = []
            self.worksets = []
            self.backoffs = []
        }

        let count = warmups.count + worksets.count + backoffs.count
        self._underway = State(initialValue: count > 1 && exercise.current!.setIndex > 0)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Group {
                    Text(exercise.name + self.display.edited).font(.largeTitle)   // OHP
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
                    .actionSheet(isPresented: $updateRepsDone) {
                        ActionSheet(title: Text("Reps Completed"), buttons: repsDoneButtons())}
                    .alert(isPresented: $updateExpected) { () -> Alert in
                        Alert(title: Text("Do you want to updated expected reps?"),
                            primaryButton: .default(Text("Yes"), action: {
                                self.exercise.expected.reps = self.completed
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
                    .sheet(isPresented: self.$historyModal) {HistoryView(history: self.display.history, workout: self.workout, exercise: self.exercise)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
                    .sheet(isPresented: self.$noteModal) {NoteView(formalName: self.exercise.formalName)}
                Button("Apparatus", action: onApparatus)
                    .font(.callout)
                    .disabled(self.exercise.isBodyWeight())
                    .sheet(isPresented: self.$apparatusModal) {EditFWSsView(self.exercise)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditRepRangesView(workout: self.workout, exercise: self.exercise)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.onTimer()}
            .onAppear {self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }
    
    func repsDoneButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        let range = getRepRange()
        let expect = expected()
        for reps in max(range.min - 6, 0)...range.max {
            // TODO: better to use bold() or underline() but they don't do anything
            let str = reps == expect ? "•• \(reps) Reps ••" : "\(reps) Reps"
            let text = Text(str)
            
            buttons.append(.default(text, action: {() -> Void in self.onRepsPressed(reps)}))
        }
        
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func onRepsPressed(_ reps: Int) {
        let percent = getRepsSet().percent
        let weight = exercise.expected.weight * percent
        if percent.value >= 0.01 && weight >= 0.1 {
            self.display.send(.AppendCurrent(self.exercise, "\(reps) reps", friendlyUnitsWeight(weight)))
        } else {
            self.display.send(.AppendCurrent(self.exercise, "\(reps) reps", ""))
        }

        self.startTimer = startDuration(-1) > 0
        self.completed.append(reps)

        let count = warmups.count + worksets.count + backoffs.count
        self.underway = count > 1 && exercise.current!.setIndex > 0
    }
    
    func onTimer() {
        if self.exercise.current!.setIndex > 0 {
            self.onReset()
        }
    }
    
    func popView() {
        self.display.send(.AppendHistory(self.workout, self.exercise))
        self.display.send(.ResetCurrent(self.exercise))

        self.presentation.wrappedValue.dismiss()
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
    
    func onApparatus() {
        self.apparatusModal = true
    }
    
    func startDuration(_ delta: Int) -> Int {
        return getRepsSet(delta).restSecs
    }
    
    func timerDuration() -> Int {
        var secs = 0
        let count = warmups.count + worksets.count + backoffs.count
        if exercise.current!.setIndex < count {
            secs = getRepsSet().restSecs
        } else {
            secs = worksets.last!.restSecs
        }
        
        return secs > 0 ? secs : 60
    }
    func onReset() {
        self.display.send(.ResetCurrent(self.exercise))
        self.completed = []
    }
        
    func onEdit() {
        self.editModal = true
    }
    
    func onNextOrDone() {
        switch stage() {
        case .warmup:
            self.display.send(.AdvanceCurrent(self.exercise))
            self.startTimer = startDuration(-1) > 0

            let count = warmups.count + worksets.count + backoffs.count
            self.underway = count > 1 && exercise.current!.setIndex > 0

        case .workset, .backoff:
            self.updateRepsDone = true

        case .done:
            if !self.completed.elementsEqual(self.exercise.expected.reps) {
                self.updateRepsDone = false
                self.startTimer = false
                self.updateExpected = true

            } else {
                self.popView()
            }
        }
    }
    
    private enum Stage {
        case warmup
        case workset
        case backoff
        case done
    }
    
    private func stage(delta: Int = 0) -> Stage {
        var i = self.exercise.current!.setIndex + delta
        if i < self.warmups.count {
            return .warmup
        }
        i -= self.warmups.count

        if i < self.worksets.count {
            return .workset
        }
        i -= self.worksets.count

        if i < self.backoffs.count {
            return .backoff
        }
        
        return .done
    }
    
    private func getRepsSet(_ delta: Int = 0) -> RepsSet {
        var i = self.exercise.current!.setIndex + delta

        if i < warmups.count {
            return warmups[i]
        }
        i -= warmups.count

        if i < worksets.count {
            return worksets[i]
        }
        i -= worksets.count

        if i < backoffs.count {
            return backoffs[i]
        }

        assert(false)
        return RepsSet(reps: RepRange(5))
    }

    private func getRepRange() -> RepRange {
        let reps = getRepsSet().reps
        switch stage() {
        case .warmup:
            return reps

        default:
            let i = self.exercise.current!.setIndex -  warmups.count
            if i < exercise.expected.reps.count {
                let expected = exercise.expected.reps[i]
                if expected < reps.max {
                    return RepRange(min: expected, max: reps.max)
                } else {
                    return RepRange(expected)
                }
            } else {
                return reps
            }
        }
    }

    private func expected() -> Int {
        switch stage() {
        case .warmup:
            return getRepsSet().reps.min

        default:
            let i = self.exercise.current!.setIndex -  warmups.count
            if i < exercise.expected.reps.count {
                return exercise.expected.reps[i]
            } else {
                return getRepsSet().reps.min
            }
        }
    }

    func getSetTitle() -> String {
        switch stage() {
        case .warmup:
            let i = exercise.current!.setIndex
            return "Warmup \(i+1) of \(warmups.count)"  // some duplication here but it's awkward to get rid of

        case .workset:
            let i = exercise.current!.setIndex - warmups.count
            if warmups.count + backoffs.count == 0 {
                return "Set \(i+1) of \(worksets.count)"
            } else {
                return "Workset \(i+1) of \(worksets.count)"
            }

        case .backoff:
            let i = exercise.current!.setIndex - warmups.count - worksets.count
            return "Backoff \(i+1) of \(backoffs.count)"

        case .done:
            return "Finished"
        }
    }
    
    func getPercentTitle() -> String {
        if !exercise.overridePercent.isEmpty {
            return exercise.overridePercent
        }
        
        switch stage() {
        case .done:
            return ""
            
        default:
            let percent = getRepsSet().percent
            let suffix = weightSuffix(percent, exercise.expected.weight)
            return !suffix.isEmpty ? "\(percent.label) of \(exercise.expected.weight) lbs" : ""
        }
    }
    
    func getRepsTitle() -> String {
        switch stage() {
        case .done:
            return ""
            
        default:
            let percent = getRepsSet().percent
            let suffix = weightSuffix(percent, exercise.expected.weight)
            return getRepRange().label + suffix
        }
    }
    
    func getPlatesTitle() -> String {
        switch stage() {
        case .done:
            return ""
            
        default:
            return ""        // TODO: needs to use apparatus
        }
    }
    
    func getStartLabel() -> String {
        switch stage() {
        case .done:
            return "Done"
            
        default:
            return "Next"
        }
    }
    
    func getNoteLabel() -> String {
        func shouldTrackHistory() -> Bool {
            // TODO: also true if apparatus is barbell, dumbbell, or machine
            if self.worksets[0].reps.min < self.worksets[0].reps.max {
                return true
            }
            return false
        }
        
        if shouldTrackHistory() {
            return getPreviouslabel(workout, exercise)
        }
        
        return ""
    }

    func getTimerTitle() -> String {
        let prefix = self.durationModal ? "On" : "Did"
        if warmups.count + backoffs.count == 0 {
            let delta = self.durationModal ? 1 : 0
            let i = exercise.current!.setIndex
            return "\(prefix) set \(i+delta) of \(worksets.count)"

        } else {
            let d1 = self.durationModal ? 0 : -1
            let d2 = self.durationModal ? 1 : 0
            switch stage(delta: d1) {
            case .warmup:
                let i = exercise.current!.setIndex
                return "\(prefix) warmup \(i+d2) of \(warmups.count)"

            case .workset:
                let i = exercise.current!.setIndex - warmups.count
                return "\(prefix) workset \(i+d2) of \(worksets.count)"

            case .backoff:
                let i = exercise.current!.setIndex - warmups.count - worksets.count
                return "\(prefix) backoff \(i+d2) of \(backoffs.count)"

            case .done:
                return "Finished"
            }
        }
    }
}

struct ExerciseRepRangesView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[2]
    static let exercise = workout.exercises.first(where: {$0.name == "Split Squat"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseRepRangesView(display, workout, exercise)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
