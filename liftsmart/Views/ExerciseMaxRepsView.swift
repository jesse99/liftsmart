//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseMaxRepsView: View {
    let workout: Workout
    var exercise: Exercise
    var history: History
    let restSecs: [Int]
    let targetReps: Int?
    @State var completed: Int = 0
    @State var startModal: Bool = false
    @State var durationModal: Bool = false
    @State var historyModal: Bool = false
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
        
        self.exercise.initCurrent(numSets: self.restSecs.count)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Curls
                Spacer()
            
                Text(title()).font(.title)              // Set 1 of 1
                Text(subTitle()).font(.headline)        // 10+ Reps or As Many Reps As Possible
                Text(subSubTitle()).font(.headline)     // Completed 30 reps (target is 90 reps)
                Spacer()

                Button(startLabel(), action: onStart)
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
                Button("Notes", action: onNotes).font(.callout)
                Button("Options", action: onOptions).font(.callout)
            }.padding()
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
        self.underway = self.restSecs.count > 1
    }
    
    func onReset() {
        self.completed = 0
        self.exercise.current!.setIndex = 0
        self.underway = false
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
    
    func title() -> String {
        if exercise.current!.setIndex < restSecs.count {
            return "Set \(exercise.current!.setIndex+1) of \(restSecs.count)"
        } else if restSecs.count == 1 {
            return "Finished"
        } else {
            return "Finished all \(restSecs.count) sets"
        }
    }
    
    func subTitle() -> String {
        if exercise.current!.setIndex >= restSecs.count {
            return ""
        }
        
        var suffix = ""
        if exercise.expected.weight > 0.0 {
            suffix = " @ " + friendlyUnitsWeight(exercise.expected.weight)
        }

        return "\(expected())+ reps \(suffix)"
    }

    func subSubTitle() -> String {
        if self.completed > 0 {
            if let target = self.targetReps {
                return "Completed \(self.completed) reps (target is \(target) reps)"
            } else {
                return "Completed \(self.completed) reps"
            }

        } else {
            if let target = self.targetReps {
                return "Target is \(target) reps"
            }
        }
        return ""
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
    
    func startLabel() -> String {
        if (exercise.current!.setIndex == restSecs.count) {
            return "Done"
        } else {
            return "Next"
        }
    }
}

struct ExerciseMaxRepsView_Previews: PreviewProvider {
    static let restSecs = [60, 30, 15]
    static let sets = Sets.maxReps(restSecs: restSecs)
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Curls", "Curls", modality, Expected(weight: 9.0))
//    static let exercise = Exercise("Curls", "Curls", modality, Expected(weight: 9.0, reps: 65))
    static let workout = Workout("Cardio", [exercise])!

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseMaxRepsView(workout, exercise, History())
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
