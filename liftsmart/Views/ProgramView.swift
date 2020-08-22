//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct Info {
    let name: String            // workout name (these are unique)
    let latest: Date?           // date latest exercise was completed
    let latestIsComplete: Bool  // true if all exercises were completed on latest date
    let completedAll: Bool      // true if all exercises were ever completed
    let days: [Bool]
}

struct ProgramView: View {
    var program: Program
    var history: History
    let timer = RestartableTimer(every: TimeInterval.minutes(30))
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
        subData = getSubData()
    }
    
    // The goal here is to highlight what the user should be doing today or what they should be doing next.
    // It's not always possible to do that with exactness but, if that's the case, we'll provide information
    // to help them decide what to do.
    func getSubData() -> [(String, Color)] {
        var result: [(String, Color)] = []

        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        let todaysWorkouts = infos.filter({$0.days[weekday - 1]})  // workouts that should be performed today
        var nextWorkout: (Int, Int)? = nil
        for delta in 1...6 {
            for info in infos {
                if nextWorkout == nil {
                    if let candidate = (cal as NSCalendar).date(byAdding: .day, value: delta, to: Date()) {
                        let weekday = cal.component(.weekday, from: candidate)
                        if info.days[weekday - 1] {
                            nextWorkout = (weekday, delta)              // next workout scheduled after today
                        }
                    }
                }
            }
        }

        for info in infos {
            // If the user has done any exercise within the workout today,
            if let last = info.latest, cal.isDate(last, inSameDayAs: Date()) {  // TODO: all these same/next day checks should be fuzzy
                if info.latestIsComplete {
                    // and they completed every exercise.
                    result.append(("completed", .black))

                } else {
                    // there are exercises within the workout that they haven't done.
                    result.append(("in progress", .red))
                }
            
            // If the workout can be performed on any day (including days on which other workouts are scheduled),
            } else if isAnyDay(info.days) {
                if let last = info.latest {
                    result.append((last.friendlyName(), .orange))
                } else {
                    result.append(("never started", .orange))
                }
            
            // If the workout is scheduled for today,
            } else if todaysWorkouts.findLast({$0.name == info.name}) != nil {
                if todaysWorkouts.count == 1 {
                    // if it's the only workout that should be done today then we have a clear winner.
                    result.append(("today", .red))
                } else {
                    // otherwise we'll tell the user how long it's been so that he can decide.
                    if let last = info.latest {
                        result.append((last.friendlyName(), .orange))
                    } else {
                        result.append(("never started", .orange))
                    }
                }
                
            // If the workout is on a day that the user should do next and the user has nothing scheduled today,
            } else if let (weekday, delta) = nextWorkout, info.days[weekday - 1] && todaysWorkouts.isEmpty {
                if delta == 1 {
                    result.append(("tomorrow", .blue))
                } else {
                    result.append(("in \(delta) days", .blue))
                }

            } else {
                result.append(("", .black))
            }
        }
        
        return result
    }
        
    // The workout can be performed on any day.
    private func isAnyDay(_ days: [Bool]) -> Bool {
        return days.all({!$0})
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
                infos.append(Info(name: workout.name, latest: last, latestIsComplete: didAll && allOnSameDay(dates), completedAll: didAll, days: workout.days))

            } else {
                infos.append(Info(name: workout.name, latest: nil, latestIsComplete: false, completedAll: false, days: workout.days))
            }
        }
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
            Workout("Cardio", [burpees(), squats()], day: nil)!,
            Workout("Lower", [burpees(), squats()], day: .wednesday)!,
            Workout("Upper", [planks(), curls()], day: .monday)!]
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
