//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseDurationsView: View {
    var exercise: Exercise
    let durations: [DurationSet]
    let targetDuration: Int?
    @State var start_modal: Bool = false
    @State var timer_modal: Bool = false
    @State var setIndex: Int = 0
    @Environment(\.presentationMode) private var presentation
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(title()).font(.title)              // Set 1 of 1
                Text(subTitle()).font(.headline)        // 60s
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
        // TODO:
        // update current (can do this with an onDismiss: callback, probably need another show_timer var)
        // curent should also be updated if user hits back button mid-set
        // when come back setIndex should be set to current value
        if setIndex < durations.count {
            self.start_modal = true
        } else {
            // Pop this view. Note that currently this only works with a real device,
            self.presentation.wrappedValue.dismiss()
        }
    }
    
    func onStartCompleted() {
        self.setIndex += 1
    }
    
    func onStartTimer() {
        self.timer_modal = true
    }
    
    func duration() -> Int {
        if setIndex < durations.count {
            return durations[setIndex].secs
        } else {
            return durations.last!.secs
        }
    }
    
    func title() -> String {
        if setIndex < durations.count {
            return "Set \(setIndex+1) of \(durations.count)"
        } else if durations.count == 1 {
            return "Finished"
        } else {
            return "Finished all \(durations.count) sets"
        }
    }

    func subTitle() -> String {
        if setIndex >= durations.count {
            return ""
        }

        let duration = durations.last!
        if let target = targetDuration {
            return "\(duration) (target is \(target)x)"
        } else {
            return "\(duration)"
        }
    }
    
    func startLabel() -> String {
        if setIndex == 0 {
            return "Start"
        } else if (setIndex == durations.count) {
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

struct ExerciseView_Previews: PreviewProvider {
    static let durations = [DurationSet(secs: 60, restSecs: 60)!, DurationSet(secs: 30, restSecs: 60)!, DurationSet(secs: 15, restSecs: 60)!]
    static let sets = Sets.durations(durations)
    static let modality = Modality(Apparatus.bodyWeight, sets)
    static let exercise = Exercise("Burpees", "Burpees", modality)

    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseDurationsView(exercise: exercise, durations: durations, targetDuration: nil)
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
