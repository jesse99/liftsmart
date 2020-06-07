//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseMaxRepsView: View {
    var exercise: Exercise
    let restSecs: [Int]
    let targetReps: Int?
    @State var completed: Int = 0
    @State var startModal: Bool = false
    @State var durationModal: Bool = false
    @State var showingSheet: Bool = false
    @State var underway: Bool = false
    @Environment(\.presentationMode) private var presentation
    
    init(_ exercise: Exercise) {
        self.exercise = exercise

        switch exercise.modality.sets {
        case .maxReps(let rs, targetReps: let t):
            self.restSecs = rs
            self.targetReps = t
        default:
            assert(false)   // exercise must use maxReps sets
            self.restSecs = []
            self.targetReps = nil
        }
        
        self.exercise.initCurrent()
        if self.exercise.current!.setIndex >= self.restSecs.count {
            // TODO: May just want to come back to the finished state, especially
            // if we have some sort of history view here.
           self.exercise.current!.setIndex = 0
        }
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Curls
                Spacer()
            
                Text(title()).font(.title)              // Set 1 of 1
                Text(subTitle()).font(.headline)        // 10+ Reps or As Many Reps As Possible
                Spacer()

                Button(startLabel(), action: onStart)
                    .font(.system(size: 40.0))
                    .actionSheet(isPresented: $showingSheet) {
                        ActionSheet(title: Text("Reps Completed"), buttons: sheetButtons())}
                    .sheet(isPresented: self.$startModal, onDismiss: self.onStartCompleted) {TimerView(duration: self.duration())}
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$durationModal) {TimerView(duration: self.duration())}
                Spacer()
            }

            Divider()
            HStack {
                // We have to use underway because body will be updated when a @State var changes
                // but not when some nested field (like exercise.current!.setIndex changes).
                Button("Reset", action: onReset).font(.callout).disabled(!self.underway)
                Spacer()
                Button("Notes", action: onNotes).font(.callout)
                // TODO: Do we want a history button? or maybe some sort of details view?
                Button("Options", action: onOptions).font(.callout)
            }.padding()
        }
    }
    
    func sheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        let delta = 10  // we'll show +/- this many reps versus expected
        
        let reps = expected()!
        for reps in max(reps - delta, 1)...(reps + delta) {
            buttons.append(.default(Text("\(reps) Reps"), action: {() -> Void in self.onSheetCompleted(reps)}))
        }
        
        return buttons
    }
    
    func onSheetCompleted(_ reps: Int) {
        self.exercise.current!.setIndex += 1    // need to do this here so that setIndex is updated before subTitle gets evaluated
        self.startModal = true
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
            if expected() != nil {
                self.showingSheet = true
            } else {
                self.startModal = true
            }
        } else {
            // Pop this view. Note that currently this only works with a real device,
            self.exercise.current!.date = Date()
            self.exercise.current!.weight = exercise.expected.weight
            self.presentation.wrappedValue.dismiss()
        }
    }
    
    func onStartCompleted() {
        if expected() == nil {
            self.exercise.current!.setIndex += 1
            self.underway = self.restSecs.count > 1
        }
    }
    
    func onStartTimer() {
        self.durationModal = true
    }
    
    func duration() -> Int {
        return restSecs[exercise.current!.setIndex]
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

        if let reps = expected() {
            return "\(reps)+ Reps \(suffix)"
        } else {
            return "As Many Reps As Possible \(suffix)"
        }
    }

    func expected() -> Int? {
        if let expected = exercise.expected.reps {
            let remaining = expected - self.completed
            let reps = remaining/(restSecs.count - exercise.current!.setIndex)
            return reps
        } else {
            return nil
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
    static let exercise = Exercise("Curls", "Curls", modality, Expected(weight: 9.0, reps: 65))

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseMaxRepsView(exercise)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
