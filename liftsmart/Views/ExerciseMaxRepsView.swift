//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseMaxRepsView: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    let restSecs: [Int]
    let targetReps: Int?
    var timer = RestartableTimer(every: TimeInterval.hours(Exercise.window/2))
    @State var title: String = ""
    @State var subTitle: String = ""
    @State var subSubTitle: String = ""
    @State var startLabel: String = ""
    @State var completed: Int = 0
    @State var startModal: Bool = false
    @State var durationModal: Bool = false
    @State var historyModal: Bool = false
    @State var noteModal: Bool = false
    @State var updateModal: Bool = false
    @State var showingSheet: Bool = false
    @State var underway: Bool = false
    @Environment(\.presentationMode) private var presentation
    
    init(_ workout: Workout, _ exercise: Exercise, _ history: History) {
        self.workout = workout
        self.exercise = exercise
        self.history = history

        switch exercise.modality.sets {
        case .maxReps(let rs, targetReps: let t):
            self.restSecs = rs
            self.targetReps = t
        default:
            assert(false)   // exercise must use maxReps sets
            self.restSecs = []
            self.targetReps = nil
        }
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Curls
                Spacer()
            
                Text(title).font(.title)              // Set 1 of 1
                Text(subTitle).font(.headline)        // 10+ Reps or As Many Reps As Possible
                Text(subSubTitle).font(.headline)     // Completed 30 reps (target is 90 reps)
                Spacer()

                Button(startLabel, action: onStart)
                    .font(.system(size: 40.0))
                    .actionSheet(isPresented: $showingSheet) {
                        ActionSheet(title: Text("Reps Completed"), buttons: sheetButtons())}
                    .alert(isPresented: $updateModal) { () -> Alert in
                        Alert(title: Text("Do you want to updated expected reps?"),
                            primaryButton: .default(Text("Yes"), action: {
                                self.exercise.expected.reps = self.completed
                                self.popView()}),
                            secondaryButton: .default(Text("No"), action: {
                                self.popView()
                            }))}
                    .sheet(isPresented: self.$startModal) {TimerView(duration: self.startDuration(-1))}
                
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
    
    func sheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        let delta = 10  // we'll show +/- this many reps versus expected
        
        let target = expected()
        for reps in max(target - delta, 1)...(target + delta) {
            let text = Text("\(reps) Reps") // TODO: would be nice to style this if target == reps but bold() and underline() don't do anything
            buttons.append(.default(text, action: {() -> Void in self.onSheetCompleted(reps)}))
        }
        
        return buttons
    }
    
    func onSheetCompleted(_ reps: Int) {
        self.exercise.current!.setIndex += 1    // need to do this here so that setIndex is updated before subTitle gets evaluated
        self.startModal = startDuration(-1) > 0
        self.completed += reps
        self.refresh()      // note that dismissing a sheet does not call onAppear
    }
    
    func onAppear() {
        if exercise.shouldReset(numSets: restSecs.count) {
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
        self.underway = self.restSecs.count > 1 && exercise.current!.setIndex > 0

        if exercise.current!.setIndex < restSecs.count {
            title = "Set \(exercise.current!.setIndex+1) of \(restSecs.count)"
        } else if restSecs.count == 1 {
            title = "Finished"
        } else {
            title = "Finished all \(restSecs.count) sets"
        }

        if exercise.current!.setIndex >= restSecs.count {
            subTitle =  ""
        } else {
            var suffix = ""
            if exercise.expected.weight > 0.0 {
                suffix = " @ " + friendlyUnitsWeight(exercise.expected.weight)
            }

            subTitle =  "\(expected())+ reps \(suffix)"
        }

        subSubTitle = ""
        if self.completed > 0 {
            if let expected = exercise.expected.reps {
                if exercise.current!.setIndex < restSecs.count {
                    subSubTitle = "Did \(self.completed) reps (expecting \(expected) reps)"
                } else if self.completed == expected {
                    subSubTitle = "Did all \(expected) expected reps"
                } else if self.completed < expected {
                    subSubTitle = "Missed \(expected - self.completed) of \(expected) expected reps"
                } else {
                    subSubTitle = "Extra \(self.completed - expected) of \(expected) expected reps"
                }
            } else {
                subSubTitle = "Did \(self.completed) reps"
            }

        } else {
            if let expected = exercise.expected.reps {
                if exercise.current!.setIndex < restSecs.count {
                    subSubTitle = "Expecting \(expected) reps"
                } else {
                    subSubTitle = "Expected \(expected) reps"
                }
            }
        }

        if (exercise.current!.setIndex == restSecs.count) {
            startLabel = "Done"
        } else {
            startLabel = "Next"
        }
    }
    
    func onReset() {
        self.exercise.current = Current(weight: self.exercise.expected.weight)
        self.completed = 0
        self.refresh()
    }
    
    func onNotes() {
        print("Pressed options")  // TODO: implement
    }
    
    func onOptions() {
        print("Pressed options")  // TODO: implement
    }
    
    func onStart() {
        if exercise.current!.setIndex < restSecs.count {
            self.showingSheet = true
        } else if self.exercise.expected.reps == nil || self.completed != self.exercise.expected.reps! {
            self.showingSheet = false
            self.startModal = false
            self.updateModal = true
        } else {
            self.popView()
        }
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
        return restSecs[exercise.current!.setIndex + delta]
    }
    
    func timerDuration() -> Int {
        var secs = 0
        if exercise.current!.setIndex < restSecs.count {
            secs = restSecs[exercise.current!.setIndex]
        } else {
            secs = restSecs.last!
        }
        
        return secs > 0 ? secs : 60
    }
    
    func expected() -> Int {
        if let expected = exercise.expected.reps {
            if exercise.current!.setIndex < restSecs.count {
                let remaining = expected - self.completed
                let reps = remaining/(restSecs.count - exercise.current!.setIndex)
                return reps
            } else {
                return 0
            }
        } else {
            return 12
        }
    }
}

struct ExerciseMaxRepsView_Previews: PreviewProvider {
    static let restSecs = [60, 30, 15]
    static let sets = Sets.maxReps(restSecs: restSecs)
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Curls", "Curls", modality, Expected(weight: 9.0))
//    static let exercise = Exercise("Curls", "Curls", modality, Expected(weight: 9.0, reps: 65))
    static let workout = Workout("Cardio", [exercise], day: nil)!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseMaxRepsView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
