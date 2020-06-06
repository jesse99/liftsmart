//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseMaxRepsView: View {
    var exercise: Exercise
    let restSecs: [Int]
    let targetReps: Int?
    @State var start_modal: Bool = false
    @State var timer_modal: Bool = false
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
                Text(subTitle()).font(.headline)        // "Max Reps"
                Spacer()

                Button(startLabel(), action: onStart)
                    .font(.system(size: 40.0))
                    .sheet(isPresented: self.$start_modal, onDismiss: self.onStartCompleted) {TimerView(duration: self.duration())}
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$timer_modal) {TimerView(duration: self.duration())}
                Spacer()
            }
            
            Divider()
            HStack {
                Button("Notes", action: onNotes).font(.callout)
                Spacer()
                // TODO: Do we want a history button? or maybe some sort of details view?
                Button("Options", action: onOptions).font(.callout)
            }.padding()
        }
    }
    
    func onNotes() {
        print("Pressed options")  // TODO: implement
    }
    
    func onOptions() {
        print("Pressed options")  // TODO: implement
    }
    
    func onStart() {
        if exercise.current!.setIndex < restSecs.count {
            self.start_modal = true
        } else {
            // Pop this view. Note that currently this only works with a real device,
            self.exercise.current!.weight = exercise.expected.weight
            self.presentation.wrappedValue.dismiss()
        }
    }
    
    func onStartCompleted() {
        self.exercise.current!.setIndex += 1
    }
    
    func onStartTimer() {
        self.timer_modal = true
    }
    
    func duration() -> Int {    // TODO: this should be restSec or some such
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

    // TODO: If there is an expected weight I think we'd annotate this label.
    // TODO: Would be nice to do something with history, maybe here or at the bottom of the exercise view.
    func subTitle() -> String {
        return "Max Reps"
    }
    
    func startLabel() -> String {
        if exercise.current!.setIndex == 0 {
            return "Start"
        } else if (exercise.current!.setIndex == restSecs.count) {
            return "Done"
        } else {
            return "Next"
        }
    }

    func weight(_ reps: RepsSet) -> String {
        if let current = exercise.current {
            return "\(Int(current.weight * reps.percent)) lbs"  // TODO: need to use apparatus
            
        } else {
            return reps.percent.label
        }
    }
}

struct ExerciseMaxRepsView_Previews: PreviewProvider {
    static let restSecs = [60, 30, 15]
    static let sets = Sets.maxReps(restSecs: restSecs)
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Curls", "Curls", modality)

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseDurationsView(exercise)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
