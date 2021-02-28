//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseFixedRepsView: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    var timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @State var worksets: [RepsSet] = []
    @State var setTitle = ""
    @State var percentTitle = ""
    @State var repsTitle = ""
    @State var platesTitle = ""
    @State var startLabel = ""
    @State var noteLabel = ""
    @State var completed: [Int] = []  // number of reps the user has done so far
    @State var startTimer = false
    @State var durationModal = false
    @State var historyModal = false
    @State var noteModal = false
    @State var apparatusModal = false
    @State var editModal = false
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
                Button("Apparatus", action: onApparatus)
                    .font(.callout)
                    .disabled(self.exercise.isBodyWeight())
                    .sheet(isPresented: self.$apparatusModal) {EditFWSsView(self.exercise)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal, onDismiss: self.refresh) {EditFixedRepsView(workout: self.workout, exercise: self.exercise)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.onTimer()}
            .onAppear {self.onAppear(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }
    
    func onAppear() {
        let count = worksets.count
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
        func shouldTrackHistory() -> Bool {
            // TODO: also true if apparatus is barbell, dumbbell, or machine
            if self.worksets[0].reps.min < self.worksets[0].reps.max {
                return true
            }
            return false
        }
        
        switch exercise.modality.sets {
        case .fixedReps(let ws):
            self.worksets = ws
        default:
            assert(false)   // this exercise must use fixedReps sets
            self.worksets = []
        }

        let count = worksets.count
        self.underway = count > 1 && exercise.current!.setIndex > 0
        
        if inProgress() {
            let percent = getRepsSet().percent
            let weight = exercise.expected.weight * percent
            let display = percent.value >= 0.01 && percent.value <= 0.99
            self.percentTitle = display ? "\(percent.label) of \(exercise.expected.weight) lbs" : ""
            
            let reps = expected()
            self.repsTitle = reps == 1 ? "1 rep" : "\(reps) reps"
            self.repsTitle += percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""

            self.platesTitle = ""        // TODO: needs to use apparatus
            self.startLabel = "Next"
        } else {
            self.setTitle = "Finished"
            self.repsTitle =  ""
            self.percentTitle = ""
            self.platesTitle = ""
            self.startLabel = "Done"
        }
        
        if !exercise.overridePercent.isEmpty {
            self.percentTitle = exercise.overridePercent
        }

        if inProgress() {
            let i = exercise.current!.setIndex
            self.setTitle = "Workset \(i+1) of \(worksets.count)"
        } else {
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
    
    func onApparatus() {
        self.apparatusModal = true
    }

    func updateReps() {
        let reps = expected()
        self.exercise.current!.actualReps.append("\(reps) reps")

        let percent = getRepsSet().percent
        let weight = exercise.expected.weight * percent
        if percent.value >= 0.01 && weight >= 0.1 {
            self.exercise.current!.actualWeights.append(friendlyUnitsWeight(weight))
        } else {
            self.exercise.current!.actualWeights.append("")
        }

        self.timerTitle = "Did set \(exercise.current!.setIndex+1) of \(worksets.count)"
        self.exercise.current!.setIndex += 1    // need to do this here so that setIndex is updated before percentTitle gets evaluated
        self.startTimer = startDuration(-1) > 0
        self.completed.append(reps)
        self.refresh()      // note that dismissing a sheet does not call onAppear
    }
    
    func onNextOrDone() {
        if inProgress() {
            updateReps()
        } else {
            // Most exercises ask to update expected but for fixedReps there's no real wiggle room
            // so we'll always update it.
            self.exercise.expected.reps = self.completed
            self.popView()
        }
    }
    
    private func inProgress() -> Bool {
        return self.exercise.current!.setIndex < self.worksets.count
    }
    
    func popView() {
        self.history.append(self.workout, self.exercise)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        
        // Note that currently this only works with a real device,
        self.presentation.wrappedValue.dismiss()
    }
    
    func onStartTimer() {
        if exercise.current!.setIndex+1 <= worksets.count {
            self.timerTitle = "On set \(exercise.current!.setIndex+1) of \(worksets.count)"
        } else {
            self.timerTitle = "Finished"
        }
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
        let count = worksets.count
        if exercise.current!.setIndex < count {
            secs = getRepsSet().restSecs
        } else {
            secs = worksets.last!.restSecs
        }
        
        return secs > 0 ? secs : 60
    }
    
    private func getRepsSet(_ delta: Int = 0) -> RepsSet {
        let i = self.exercise.current!.setIndex + delta

        if i < worksets.count {
            return worksets[i]
        }

        assert(false)
        return RepsSet(reps: RepRange(5))
    }

    private func expected() -> Int {
        if inProgress() {
            let i = self.exercise.current!.setIndex
            return self.exercise.expected.reps.at(i) ?? getRepsSet().reps.min
        } else {
            return getRepsSet().reps.min
        }
    }
}

struct ExerciseFixedRepsView_Previews: PreviewProvider {
    static let reps1 = RepRange(12)
    static let reps2 = RepRange(10)
    static let reps3 = RepRange(6)
//    static let workset = RepsSet(reps: reps, percent: WeightPercent(1.0)!, restSecs: 60)!
    static let work1 = RepsSet(reps: reps1, percent: WeightPercent(0.8), restSecs: 60)
    static let work2 = RepsSet(reps: reps2, percent: WeightPercent(0.9), restSecs: 60)
    static let work3 = RepsSet(reps: reps3, percent: WeightPercent(1.0))
    static let sets = Sets.fixedReps([work1, work2, work3])
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Mountain Climber", "Mountain Climber", modality, Expected(weight: 20.0))
    static let workout = createWorkout("Mobility", [exercise], day: nil).unwrap()

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseFixedRepsView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
