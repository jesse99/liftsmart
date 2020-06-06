//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseDurationsView: View { // TODO: rename this ExerciseDurationsView
    var exercise: Exercise
    let durations: [DurationSet]
    let targetDuration: Int?
    @State var start_modal: Bool = false
    @State var timer_modal: Bool = false
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(title()).font(.title)              // Set 1 of 1
                Text(subTitle()).font(.headline)        // 60s
                Spacer()

                Button("Start", action: onStart)
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
        // update title and subtitle views (probably need to have them use a @State var)
        // when run out of sets Start buttion needs to change to Done
        // when Done is pressed need to return to WorkoutView
        self.start_modal = true
    }
    
    func onStartCompleted() {
        
    }
    
    func onStartTimer() {
        self.timer_modal = true
    }
    
    func duration() -> Int {
        var setIndex = 0
        if let current = exercise.current {
            setIndex = current.setIndex
        }
        
        return durations[setIndex].secs
    }
    
    func title() -> String {
        var setIndex = 0
        if let current = exercise.current {
            setIndex = current.setIndex
        }
        
        return "Set \(setIndex+1) of \(durations.count)"
    }

    func subTitle() -> String {
        var setIndex = 0
        if let current = exercise.current {
            setIndex = current.setIndex
        }
        
        if let target = targetDuration {
            return "\(durations[setIndex]) (target is \(target)x)"

        } else {
            return "\(durations[setIndex])"
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
    static let durations = [DurationSet(secs: 60, restSecs: 60)!]
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
