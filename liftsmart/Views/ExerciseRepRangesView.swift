//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// Note that, in general, we can only report what the user has done because he may do something
// different then what we think he should.
func getPreviouslabel(_ display: Display, _ workout: Workout, _ exercise: Exercise) -> String {
    let records = display.history.exercise(workout, exercise).reversed()
    guard let text = records.first?.label, !text.isEmpty else {
        return ""
    }
    
    var count = 0
    for record in records {
        if record.label == text {
            count += 1
        } else {
            break
        }
    }
    return "Did \(text) \(count)x"
}

struct ExerciseRepRangesView: View {
    let workoutIndex: Int
    let exerciseID: Int
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var startTimer = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var editModal = false
    @State var updateExpected = false
    @State var advanceWeight = false
    @State var updateRepsDone = false
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

        let count = exercise.modality.sets.numSets()!
        self._underway = State(initialValue: count > 1 && exercise.current!.setIndex > 0)
    }
    
    var body: some View {
        let pt = self.getPercentTitle()
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Group {
                    Text(exercise().name + self.display.edited).font(.largeTitle)   // OHP
                    Spacer()
                
                    Text(self.getSetTitle()).font(.title)         // WorkSet 1 of 3
                    if !pt.isEmpty {
                        Text(pt).font(.headline)                  // 75% of 120 lbs
                        Spacer().frame(height: 25)
                    }

                    Text(self.getRepsTitle()).font(.title)        // 3-5 reps @ 120 lbs
                    Text(self.getPlatesTitle()).font(.headline)   // 25 + 10 + 2.5
                }
                Spacer()

                Button(self.getStartLabel(), action: onNextOrDone)
                    .font(.system(size: 40.0))
                    .alert(isPresented: $updateExpected) { () -> Alert in
                        Alert(title: Text("Do you want to update expected reps?"),
                            primaryButton: .default(Text("Yes"), action: {self.doAdvanceReps()}),
                            secondaryButton: .default(Text("No"), action: {self.popView()})
                        )}
                    .sheet(isPresented: $updateRepsDone) {
                        RepsPickerView(initial: self.expected(), dismissed: self.onRepsPressed)
                    }

                Spacer().frame(height: 50)
                    .alert(isPresented: $advanceWeight) { () -> Alert in
                        Alert(title: Text("Do you want to advance the weight?"),
                            primaryButton: .default(Text("Yes"), action: {self.doAdvanceWeight()}),
                            secondaryButton: .default(Text("No"), action: {self.popView()})
                        )}

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(title: self.getTimerTitle(), duration: self.timerDuration())}
                Spacer()
                Text(self.getNoteLabel()).font(.callout)   // Same previous x3
                    .sheet(isPresented: self.$startTimer) {TimerView(title: self.getTimerTitle(), duration: self.startDuration(-1))}
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

    func onRepsPressed(_ reps: Int) {
        let percent = getRepsSet().percent
        self.display.send(.AppendCurrent(self.exercise(), "\(reps) reps", percent.value))

        self.startTimer = startDuration(-1) > 0
        print("repsPressed self.startTimer: \(self.startTimer)")

        let completed = self.exercise().current!.completed + [reps]
        self.display.send(.SetCompleted(self.exercise(), completed))

        let count = self.exercise().modality.sets.numSets()!
        self.underway = count > 1 && exercise().current!.setIndex > 0
    }
    
    func onTimer() {
        if self.exercise().current!.setIndex > 0 {
            self.onReset()
        }
    }
    
    func popView() {
        self.presentation.wrappedValue.dismiss()
        self.display.send(.AppendHistory(self.workout(), self.exercise()))
        self.display.send(.ResetCurrent(self.exercise()))
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
        let count = self.exercise().modality.sets.numSets()!
        if exercise().current!.setIndex < count {
            secs = getRepsSet().restSecs
        } else {
            let (_, worksets, _) = self.getSets()
            secs = worksets.last!.restSecs
        }
        
        return secs > 0 ? secs : 60
    }
    
    func onReset() {
        self.display.send(.ResetCurrent(self.exercise()))
    }
        
    func onEdit() {
        self.editModal = true
    }
    
    func onNextOrDone() {
        switch stage() {
        case .warmup:
            self.display.send(.AdvanceCurrent(self.exercise()))
            self.startTimer = startDuration(-1) > 0
            print("warmup self.startTimer: \(self.startTimer)")

            let count = self.exercise().modality.sets.numSets()!
            self.underway = count > 1 && exercise().current!.setIndex > 0

        case .workset, .backoff:
            self.updateRepsDone = true

        case .done:
            if !self.exercise().current!.completed.elementsEqual(self.exercise().expected.reps) {
                self.updateRepsDone = false
                self.startTimer = false
                self.updateExpected = true
                
            } else if self.canAdvanceWeight() {
                self.updateRepsDone = false
                self.startTimer = false
                self.advanceWeight = true

            } else {
                self.popView()
            }
        }
    }
    
    private func doAdvanceWeight() {
        let weight = self.exercise().advanceWeight(self.display)!
        self.display.send(.SetExpectedWeight(self.exercise(), weight))
        
        let (_, worksets, _) = self.getSets()
        let reps = worksets.map({$0.reps.min})
        self.display.send(.SetExpectedReps(self.exercise(), reps))
        
        self.popView()
    }
    
    private func canAdvanceWeight() -> Bool {
        let completed = self.exercise().current!.completed
        let (_, worksets, _) = self.getSets()
        if self.exercise().advanceWeight(self.display) != nil && completed.count >= worksets.count {
            for i in 0..<worksets.count {
                if let maxReps = worksets[i].reps.max {
                    if completed[i] < maxReps {
                        return false
                    }
                } else {
                    return false    // set is min to inf
                }
            }
            return true
        }
        
        return false
    }
    
    private func doAdvanceReps() {
        let completed = self.exercise().current!.completed
        self.display.send(.SetExpectedReps(self.exercise(), completed))
        
        if canAdvanceWeight() {
            self.updateExpected = false
            
            // Swiftui doesn't seem to like back to back alerts so we wait a bit
            // before showing the second one.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.advanceWeight = true
            }
        } else {
            self.popView()
        }
    }
    
    private enum Stage {
        case warmup
        case workset
        case backoff
        case done
    }
    
    private func stage(delta: Int = 0) -> Stage {
        var i = self.exercise().current!.setIndex + delta
        let (warmups, worksets, backoffs) = self.getSets()
        if i < warmups.count {
            return .warmup
        }
        i -= warmups.count

        if i < worksets.count {
            return .workset
        }
        i -= worksets.count

        if i < backoffs.count {
            return .backoff
        }
        
        return .done
    }
    
    private func getRepsSet(_ delta: Int = 0) -> RepsSet {
        var i = self.exercise().current!.setIndex + delta
        if i < 0 {
            i = 0
        }

        let (warmups, worksets, backoffs) = self.getSets()
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

//        ASSERT(false)
        return RepsSet(reps: RepRange(min: 5, max: 5))
    }

    private func getRepRange() -> RepRange {
        let reps = getRepsSet().reps
        switch stage() {
        case .warmup:
            return reps

        default:
            let (warmups, _, _) = self.getSets()
            let i = self.exercise().current!.setIndex - warmups.count
            if i < exercise().expected.reps.count {
                let expected = exercise().expected.reps[i]
                if let max = reps.max {
                    if expected < max {
                        return RepRange(min: expected, max: max)
                    } else {
                        return RepRange(min: expected, max: expected)
                    }
                } else {
                    return RepRange(min: expected, max: nil)
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
            let (warmups, _, _) = self.getSets()
            let i = self.exercise().current!.setIndex - warmups.count
            if i < exercise().expected.reps.count {
                return exercise().expected.reps[i]
            } else {
                return getRepsSet().reps.min
            }
        }
    }

    func getSetTitle() -> String {
        let (warmups, worksets, backoffs) = self.getSets()
        switch stage() {
        case .warmup:
            let i = exercise().current!.setIndex
            return "Warmup \(i+1) of \(warmups.count)"  // some duplication here but it's awkward to get rid of

        case .workset:
            let i = exercise().current!.setIndex - warmups.count
            if warmups.count + backoffs.count == 0 {
                return "Set \(i+1) of \(worksets.count)"
            } else {
                return "Workset \(i+1) of \(worksets.count)"
            }

        case .backoff:
            let i = exercise().current!.setIndex - warmups.count - worksets.count
            return "Backoff \(i+1) of \(backoffs.count)"

        case .done:
            return "Finished"
        }
    }
    
    func getWeightSuffix(_ percent: WeightPercent) -> Either<String, String> {
        var closest: Either<String, Double>
        let exercise = self.exercise()

        switch stage() {
        case .warmup:
            closest = exercise.getClosest(self.display, exercise.expected.weight*percent)
        case .workset:
            closest = exercise.getClosestBelow(self.display, exercise.expected.weight*percent)
        case .backoff:
            closest = exercise.getClosest(self.display, exercise.expected.weight*percent)
        case .done:
            return .right("")
        }
        
        switch closest {
        case .right(let weight):
            let suffix = percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
            return .right(suffix)
        case .left(let err):
            return .left(err)
        }
    }
    
    func getPercentTitle() -> String {
        let exercise = self.exercise()
        if !exercise.overridePercent.isEmpty {
            return exercise.overridePercent
        }
        
        let percent = getRepsSet().percent
        if case .workset = stage() {
            let (_, worksets, _) = self.getSets()
            if worksets.all({$0.percent.label == "100%"}) {
                if case .right(let weight) = exercise.getClosestBelow(self.display, exercise.expected.weight), abs(weight - exercise.expected.weight) < 1 {
                    return ""
                } else {
                    return "Expecting \(friendlyUnitsWeight(exercise.expected.weight))"
                }
            }
        }
        
        switch self.getWeightSuffix(percent) {
        case .right(let suffix):
            return !suffix.isEmpty ? "\(percent.label) of \(exercise.expected.weight) lbs" : ""
        case .left(let err):
            return err
        }
    }
    
    func getRepsTitle() -> String {
        switch stage() {
        case .done:
            return ""
            
        default:
            let percent = getRepsSet().percent
            switch self.getWeightSuffix(percent) {
            case .right(let suffix):
                return getRepRange().label + suffix
            case .left(_):
                return getRepRange().label
            }
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
            let (_, worksets, _) = self.getSets()
            if let reps = worksets.first?.reps {
                if let max = reps.max {
                    if reps.min < max {
                        return true
                    }
                } else {
                    return true
                }
            }
            return false
        }
        
        if shouldTrackHistory() {
            return getPreviouslabel(self.display, workout(), exercise())
        }
        
        return ""
    }

    func getTimerTitle() -> String {
        let prefix = self.durationModal ? "On" : "Did"
        let (warmups, worksets, backoffs) = self.getSets()
        if warmups.count + backoffs.count == 0 {
            let delta = self.durationModal ? 1 : 0
            let i = exercise().current!.setIndex
            return "\(prefix) set \(i+delta) of \(worksets.count)"

        } else {
            let d1 = self.durationModal ? 0 : -1
            let d2 = self.durationModal ? 1 : 0
            switch stage(delta: d1) {
            case .warmup:
                let i = exercise().current!.setIndex
                return "\(prefix) warmup \(i+d2) of \(warmups.count)"

            case .workset:
                let i = exercise().current!.setIndex - warmups.count
                return "\(prefix) workset \(i+d2) of \(worksets.count)"

            case .backoff:
                let i = exercise().current!.setIndex - warmups.count - worksets.count
                return "\(prefix) backoff \(i+d2) of \(backoffs.count)"

            case .done:
                return "Finished"
            }
        }
    }
    
    // TODO: some of these can be replaced with numSets()
    private func getSets() -> ([RepsSet], [RepsSet], [RepsSet]) {
        switch exercise().modality.sets {
        case .repRanges(warmups: let wu, worksets: let ws, backoffs: let bo):
            return (wu, ws, bo)
        default:
//            ASSERT(false)   // this exercise must use repRanges sets
            return ([], [], [])
        }
    }
}

struct ExerciseRepRangesView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex = 2
    static let workout = display.program.workouts[workoutIndex]
    static let exercise = workout.exercises.first(where: {$0.name == "Split Squat"})!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseRepRangesView(display, workoutIndex, exercise.id)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
