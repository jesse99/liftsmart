//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseRepRangesView: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    let warmups: [RepsSet]
    let worksets: [RepsSet]
    let backoffs: [RepsSet]
//    let targetReps: Int?
    var timer = RestartableTimer(every: TimeInterval.hours(Exercise.window/2))
    @State var title: String = ""
    @State var subTitle: String = ""
    @State var startLabel: String = ""
    @State var completed: [Int] = []  // number of reps the user has done so far (not counting warmup)
    @State var startTimer: Bool = false
    @State var durationModal: Bool = false
    @State var historyModal: Bool = false
    @State var noteModal: Bool = false
    @State var updateExpected: Bool = false
    @State var updateRepsDone: Bool = false
    @State var underway: Bool = false
    @Environment(\.presentationMode) private var presentation
    
    init(_ workout: Workout, _ exercise: Exercise, _ history: History) {
        self.workout = workout
        self.exercise = exercise
        self.history = history

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
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // OHP
                Spacer()
            
                Text(title).font(.title)              // WorkSet 1 of 3
                // TODO: 75% of 120 lbs
                Text(subTitle).font(.headline)        // 3-5 reps @ 120 lbs
                // TODO: 25 + 10 + 2.5
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
                    .sheet(isPresented: self.$startTimer) {TimerView(duration: self.startDuration(-1))}
                
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(duration: self.timerDuration())}
                Spacer()
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
                Button("Options", action: onOptions).font(.callout)
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
        for reps in max(range.min - 3, 0)...range.max {
            let text = Text("\(reps) Reps") // TODO: would be nice to style this if target == reps but bold() and underline() don't do anything
            buttons.append(.default(text, action: {() -> Void in self.onRepsPressed(reps)}))
        }

        return buttons
    }
    
    func onRepsPressed(_ reps: Int) {
        self.exercise.current!.setIndex += 1    // need to do this here so that setIndex is updated before subTitle gets evaluated
        self.startTimer = startDuration(-1) > 0
        self.completed.append(reps)  // TODO: also handle fixed reps case
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

    func refresh() {
        let count = warmups.count + worksets.count + backoffs.count
        self.underway = count > 1 && exercise.current!.setIndex > 0

        switch stage() {
        case .warmup:
            let i = exercise.current!.setIndex
            self.title = "Warmup \(i+1) of \(warmups.count)"
            self.subTitle =  getRepRange().label + getWeightLabel()
            self.startLabel = "Next"

        case .workset:
            let i = exercise.current!.setIndex - warmups.count
            self.title = "Workset \(i+1) of \(worksets.count)"
            self.subTitle =  getRepRange().label + getWeightLabel()
            self.startLabel = "Next"

        case .backoff:
            let i = exercise.current!.setIndex - warmups.count - worksets.count
            self.title = "Backoff \(i+1) of \(backoffs.count)"
            self.subTitle =  getRepRange().label + getWeightLabel()
            self.startLabel = "Next"

        case .done:
            self.title = "Finished"
            self.subTitle =  ""
            self.startLabel = "Done"
        }
    }
    
    // TODO: think we need to scale Expected.weight by set.percent (note that WeightPercent overloads *)
    private func getWeightLabel() -> String {
//        var label = ""
//        if exercise.expected.weight > 0.0 {
//            label = " @ " + friendlyUnitsWeight(exercise.expected.weight)
//        }
        return ""
    }
    
    func onReset() {
        self.exercise.current = Current(weight: self.exercise.expected.weight)
        self.completed = []
        self.refresh()
    }
    
    func onNotes() {
        print("Pressed options")  // TODO: implement
    }
    
    func onOptions() {
        print("Pressed options")  // TODO: implement
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
        return RepsSet(reps: RepRange(5)!)!
    }

    private func getRepRange() -> RepRange {
        let reps = getRepsSet().reps

        let i = self.exercise.current!.setIndex - warmups.count
        if i < exercise.expected.reps.count {
            let expected = exercise.expected.reps[i]
            if expected < reps.max {
                return RepRange(min: expected, max: reps.max)!
            } else {
                return RepRange(expected)!
            }
        } else {
            return reps
        }
    }

    private func expected() -> Int {
        let i = self.exercise.current!.setIndex - warmups.count
        if i < exercise.expected.reps.count {
            return exercise.expected.reps[i]
        } else {
            let reps = getRepsSet().reps
            return reps.min
        }
    }
}

// TODO:
// use warmups
// use backoff
// use WeightPercent
// mismatched worksets, eg 8-12, 6-10, 4-6
//    should ask reps after each workset
//    then what? make Expected.reps an array?
//    might be better to just ask for reps after each workset
// review TODOs
struct ExerciseRepRangesView_Previews: PreviewProvider {
    static let reps = RepRange(min: 4, max: 8)!
    static let workset:RepsSet = RepsSet(reps: reps, percent: WeightPercent(1.0)!, restSecs: 60)!
    static let sets = Sets.repRanges(warmups: [], worksets: [workset, workset, workset], backoffs: [])
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("OHP", "OHP", modality, Expected(weight: 120.0, reps: [6, 5, 4]))
    static let workout = Workout("Strength", [exercise], day: nil)!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseRepRangesView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
