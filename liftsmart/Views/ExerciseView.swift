//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ExerciseView: View { // TODO: rename this ExerciseDurationsView
    var exercise: Exercise
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
                    .sheet(isPresented: self.$start_modal, onDismiss: self.onStartCompleted) {TimerView(duration: 60)}
                Spacer().frame(height: 50)

                Button("Start Timer", action: onStartTimer)
                    .font(.system(size: 20.0))
                    .sheet(isPresented: self.$timer_modal) {TimerView(duration: 60)}
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
        // use proper durations
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
    
    func title() -> String {
        var setIndex = 0
        if let current = exercise.current {
            setIndex = current.setIndex
        }
        
        switch exercise.modality.sets {
        case .durations(let durations, _):
            return "Set \(setIndex+1) of \(durations.count)"

        case .maxReps(let restSecs, _):
            return "Set \(setIndex+1) of \(restSecs.count)"

        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            if setIndex < warmups.count {
                return "Warmup \(setIndex+1) of \(warmups.count)"
            }
            setIndex -= warmups.count
            
            if setIndex < worksets.count {
                return "Workset \(setIndex+1) of \(worksets.count)"
            }
            setIndex -= worksets.count

            return "Backoff \(setIndex+1) of \(backoffs.count)"
        }
    }

    func subTitle() -> String {
        var setIndex = 0
        if let current = exercise.current {
            setIndex = current.setIndex
        }
        
        switch exercise.modality.sets {
        case .durations(let durations, targetDuration: let targetDuration):
            if let target = targetDuration {
                return "\(durations[setIndex]) (target is \(target)x)"

            } else {
                return "\(durations[setIndex])"
            }

        case .maxReps(_, _):
            return ""   // TODO: maybe we should say what last was?

        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            if setIndex < warmups.count {
                return "\(warmups[setIndex].reps.label) @ \(weight(warmups[setIndex]))"
            }
            setIndex -= warmups.count
            
            if setIndex < worksets.count {
                return "\(worksets[setIndex].reps.label) @ \(weight(worksets[setIndex]))"
            }
            setIndex -= worksets.count

            return "\(backoffs[setIndex].reps.label) @ \(weight(backoffs[setIndex]))"
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
    static var previews: some View {
        ForEach(["iPhone XS"], id: \.self) { deviceName in
            ExerciseView(exercise: program[0].exercises[0])
                .previewDevice(PreviewDevice(rawValue: deviceName))
        }
    }
}
