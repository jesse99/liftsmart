//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct Info {
    let latest: Date?           // date latest exercise was completed
    let latestIsComplete: Bool  // true if all exercises were completed on latest date
    let completedAll: Bool      // true if all exercises were ever completed
}

struct ProgramView: View {
    var program: Program
    var history: History
    let timer = RestartableTimer(every: TimeInterval.hours(8))
    @State var infos: [Info] = []
    @State var subData: [(String, Color)] = Array(repeating: ("", .black), count: 30)

    init(program: Program, history: History) {
        self.program = program
        self.history = history
        infos = []
    }

    var body: some View {
        NavigationView {
            List(0..<program.count) { i in
                NavigationLink(destination: WorkoutView(workout: self.program[i], history: self.history)) {
                    VStack(alignment: .leading) {
                        Text(self.program[i].name).font(.title)
                        Text(self.subData[i].0).foregroundColor(self.subData[i].1).font(.headline) // 10+ Reps or As Many Reps As Possible
                    }
                }
            }
            .navigationBarTitle(Text(program.name + " Workouts"))
            .onAppear {self.refresh(); self.timer.restart()}
            .onDisappear {self.timer.stop()}
            .onReceive(self.timer.timer) {_ in self.refresh()}
        }
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
    
    // subData will change every day so we use a timer to refresh the UI in case the user has been sitting
    // on this view for a long time.
    func refresh() {
        updateInfos()
        subData = infos.mapi({self.getSubData($0, $1)})
    }
    
    func getSubData(_ index: Int, _ info: Info) -> (String, Color) {
        if let last = info.latest {
            let cal = Calendar.current
            if cal.isDate(last, inSameDayAs: Date()) {
                // All exercises were completed today.
                if info.latestIsComplete {
                    return ("completed", .black)

                // The user is currently performing the workout but hasn't yet finished it.
                } else {
                    return ("in progress", .red)
                }

            // The workout that was started the longest ago.
            } else if isOldestWorkout(index, last) {              // workout with the oldest latest
                return (last.daysName(), .blue)

            // Workout that was started more recently.
            } else {
                return (last.daysName(), .black)
            }

        } else {
            // The user has never started the workout.
            return ("", .black)
        }
    }
    
    func updateInfos() {
        func allOnSameDay(_ dates: [Date]) -> Bool {
            let calendar = Calendar.current
            for date in dates {
                if !calendar.isDate(date, inSameDayAs: dates[0]) {
                    return false
                }
            }
            return true
        }
                
        infos = []
        for workout in program {
            var dates: [Date] = []
            for exercise in workout.exercises {
                if let completed = exercise.dateCompleted(workout, history) {
                    dates.append(completed)
                }
            }
            dates.sort()
            
            if let last = dates.last {
                let didAll = dates.count == workout.exercises.count
                infos.append(Info(latest: last, latestIsComplete: didAll && allOnSameDay(dates), completedAll: didAll))

            } else {
                infos.append(Info(latest: nil, latestIsComplete: false, completedAll: false))
            }
        }
    }

    func isOldestWorkout(_ index: Int, _ candidate: Date) -> Bool {
        for (i, info) in infos.enumerated() {
            if i != index {
                if let date = info.latest {
                    if date.compare(candidate) == .orderedAscending {
                        return false
                    }
                }
                if !info.completedAll {
                    // If there was a workout that hasn't been completed then we
                    // can't really say which is the oldest.
                    return false
                }
            }
        }
        return infos.count > 1  // oldest doesn't make much sense if there is only one
    }
}

struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(program: ProgramView_Previews.home(), history: ProgramView_Previews.history())
    }
    
    private static func home() -> Program {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func planks() -> Exercise { // TODO: this should be some sort of progression
            let durations = [
                DurationSet(secs: 60, restSecs: 90)!,
                DurationSet(secs: 60, restSecs: 90)!,
                DurationSet(secs: 60, restSecs: 90)!]
            let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Planks", "Front Plank", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func curls() -> Exercise {
            let sets = Sets.maxReps(restSecs: [90, 90, 0])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: 65))
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        let workouts = [
            Workout("Lower", [burpees(), squats()])!,
            Workout("Upper", [planks(), curls()])!]
        return Program("Split", workouts)
    }

    private static func history() -> History {
        let program = ProgramView_Previews.home()
        let history = History()
        history.append(program[0], program[0].exercises[0])
        history.append(program[0], program[0].exercises[1])
        history.append(program[1], program[1].exercises[0])
        history.append(program[1], program[1].exercises[1])
        return history
    }
}
