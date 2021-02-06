//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

func getPreviouslabel(_ workout: Workout, _ exercise: Exercise) -> String {
    var count = 0
    var actual = ""
    for record in history.exercise(workout, exercise).reversed() {
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
    var exercise: Exercise
    var history: History
    var timer = RestartableTimer(every: TimeInterval.hours(Exercise.window/2))
    @State var warmups: [RepsSet] = []
    @State var worksets: [RepsSet] = []
    @State var backoffs: [RepsSet] = []
    @State var setTitle = ""
    @State var percentTitle = ""
    @State var repsTitle = ""
    @State var platesTitle = ""
    @State var startLabel = ""
    @State var noteLabel = ""
    @State var completed: [Int] = []  // number of reps the user has done so far (not counting warmup)
    @State var startTimer = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var editModal = false
    @State var updateExpected = false
    @State var updateRepsDone = false
    @State var underway = false
    @State var timerTitle = ""
    @Environment(\.presentationMode) private var presentation
    
    init(_ workout: Workout, _ exercise: Exercise, _ history: History) {
        self.workout = workout
        self.exercise = exercise
        self.history = history
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Group {
                    Text(exercise.name).font(.largeTitle)   // OHP
                    Spacer()
                
                    Text(setTitle).font(.title)         // WorkSet 1 of 3
                    Text(percentTitle).font(.headline)  // 75% of 120 lbs
                    Spacer().frame(height: 25)

                    Text(repsTitle).font(.title)        // 3-5 reps @ 120 lbs
                    Text(platesTitle).font(.headline)   // 25 + 10 + 2.5
                }
                Spacer()

                Button(startLabel, action: onNextOrDone)
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
                    .sheet(isPresented: self.$startTimer) {TimerView(title: $timerTitle, duration: self.startDuration(-1))}
                
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(title: $timerTitle, duration: self.timerDuration())}
                Spacer()
                Text(self.noteLabel).font(.callout)   // Same previous x3
            }

            Divider()
            HStack {
                // We have to use underway because body will be updated when a @State var changes
                // but not when some nested field (like exercise.current!.setIndex changes).
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
                    .sheet(isPresented: self.$editModal, onDismiss: self.refresh) {EditRepRangesView(workout: self.workout, exercise: self.exercise)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.onTimer()}
            .onAppear {self.onAppear(); self.timer.restart()}
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

        return buttons
    }
    
    func onRepsPressed(_ reps: Int) {
        self.exercise.current!.actualReps.append("\(reps) reps")

        let percent = getRepsSet().percent
        let weight = exercise.expected.weight * percent
        if percent.value >= 0.01 && weight >= 0.1 {
            self.exercise.current!.actualWeights.append(friendlyUnitsWeight(weight))
        } else {
            self.exercise.current!.actualWeights.append("")
        }

        self.timerTitle = getSetTitle("Did")
        self.exercise.current!.setIndex += 1    // need to do this here so that setIndex is updated before percentTitle gets evaluated
        self.startTimer = startDuration(-1) > 0
        self.completed.append(reps)
        self.refresh()      // note that dismissing a sheet does not call onAppear
    }
    
    func onAppear() {
        let count = warmups.count + worksets.count + backoffs.count
        if exercise.shouldReset(numSets: count) {
            onReset()
        } else {
            refresh()
        }
    }

    func onTimer() {
        if self.exercise.current!.setIndex > 0 {
            self.onReset()
        }
    }
    
    func getSetTitle(_ prefix: String) -> String {
        switch stage() {
        case .warmup:
            let i = exercise.current!.setIndex
            return "\(prefix) warmup \(i+1) of \(warmups.count)"

        case .workset:
            let i = exercise.current!.setIndex - warmups.count
            return "\(prefix) workset \(i+1) of \(worksets.count)"

        case .backoff:
            let i = exercise.current!.setIndex - warmups.count - worksets.count
            return "\(prefix) backoff \(i+1) of \(backoffs.count)"

        case .done:
            return "Finished"
        }
    }
    
    func refresh() {
        func shouldTrackHistory() -> Bool {
            // TODO: also true if apparatus is barbell, dumbbell, or machine
            if self.worksets[0].reps.min < self.worksets[0].reps.max {
                return true
            }
            return false
        }
        
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
        self.underway = count > 1 && exercise.current!.setIndex > 0
        
        switch stage() {
        case .done:
            self.setTitle = "Finished"
            self.repsTitle =  ""
            self.percentTitle = ""
            self.platesTitle = ""
            self.startLabel = "Done"
            
        default:
            let percent = getRepsSet().percent
            let suffix = weightSuffix(percent, exercise.expected.weight)
            self.percentTitle = !suffix.isEmpty ? "\(percent.label) of \(exercise.expected.weight) lbs" : ""

            self.repsTitle = getRepRange().label + suffix
            self.platesTitle = ""        // TODO: needs to use apparatus
            self.startLabel = "Next"
        }
        
        if !exercise.overridePercent.isEmpty {
            self.percentTitle = exercise.overridePercent
        }
        
        switch stage() {
        case .warmup:
            let i = exercise.current!.setIndex
            self.setTitle = "Warmup \(i+1) of \(warmups.count)"  // some duplication here but it's awkward to get rid of

        case .workset:
            let i = exercise.current!.setIndex - warmups.count
            self.setTitle = "Workset \(i+1) of \(worksets.count)"

        case .backoff:
            let i = exercise.current!.setIndex - warmups.count - worksets.count
            self.setTitle = "Backoff \(i+1) of \(backoffs.count)"

        case .done:
            self.setTitle = "Finished"
            self.repsTitle =  ""
            self.percentTitle = ""
            self.platesTitle = ""
            self.startLabel = "Done"
        }
        
        self.noteLabel = ""
        if shouldTrackHistory() {
            self.noteLabel = getPreviouslabel(workout, exercise)
        }
    }
    
    func onReset() {
        self.exercise.current = Current(weight: self.exercise.expected.weight)
        self.completed = []
        self.refresh()
    }
        
    func onEdit() {
        self.editModal = true
    }
    
    func onNextOrDone() {
        switch stage() {
        case .warmup:
            self.exercise.current!.setIndex += 1
            self.startTimer = startDuration(-1) > 0
            self.refresh()      // note that dismissing a sheet does not call onAppear

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
    
    private func stage() -> Stage {
        var i = self.exercise.current!.setIndex
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
    
    func popView() {
        self.history.append(self.workout, self.exercise)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        
        // Note that currently this only works with a real device,
        self.presentation.wrappedValue.dismiss()
    }
    
    func onStartTimer() {
        self.timerTitle = getSetTitle("On")
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
        let count = warmups.count + worksets.count + backoffs.count
        if exercise.current!.setIndex < count {
            secs = getRepsSet().restSecs
        } else {
            secs = worksets.last!.restSecs
        }
        
        return secs > 0 ? secs : 60
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
}

struct ExerciseRepRangesView_Previews: PreviewProvider {
    static let reps1 = RepRange(min: 8, max: 12)
    static let reps2 = RepRange(min: 6, max: 10)
    static let reps3 = RepRange(min: 4, max: 6)
    static let warm1 = RepsSet(reps: RepRange(8), percent: WeightPercent(0.33))
    static let warm2 = RepsSet(reps: RepRange(4), percent: WeightPercent(0.66))
//    static let workset = RepsSet(reps: reps, percent: WeightPercent(1.0)!, restSecs: 60)!
//    static let backoff = RepsSet(reps: RepRange(4)!, percent: WeightPercent(0.8)!)!
    static let work1 = RepsSet(reps: reps1, percent: WeightPercent(0.8), restSecs: 60)
    static let work2 = RepsSet(reps: reps2, percent: WeightPercent(0.9), restSecs: 60)
    static let work3 = RepsSet(reps: reps3, percent: WeightPercent(1.0))
    static let sets = Sets.repRanges(warmups: [warm1, warm2], worksets: [work1, work2, work3], backoffs: [])
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("OHP", "OHP", modality, Expected(weight: 120.0))
    static let workout = createWorkout("Strength", [exercise], day: nil).unwrap()

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseRepRangesView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
