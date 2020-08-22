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
        var result: [(String, Color)] = Array(repeating: ("", .black), count: infos.count)

        // First we'll check to see if they have done an exercise today,
        let cal = Calendar.current
        for (index, info) in infos.enumerated() {
            var found = false               // if the user is playing catch-up he may decide to do part of another workout with the current workout
            if let last = info.latest {
                if cal.isDate(last, inSameDayAs: Date()) {  // TODO: all these same/next day checks should be fuzzy
                    if info.latestIsComplete {
                        // they've done every exercise within the workout today.
                        result[index] = ("completed", .black)
                        found = true

                    } else {
                        // there are still exercises that haven't been done.
                        result[index] = ("in progress", .red)
                        found = true
                    }
                }
            }
            if found {
                return result
            }
        }
        
        // Then we'll check to see if there are workouts that should be performed on this weekday.
        let weekday = cal.component(.weekday, from: Date())
        let todaysWorkouts = infos.filter({$0.days[weekday - 1]})
        if !todaysWorkouts.isEmpty {
            for (index, info) in infos.enumerated() {
                // If this workout should be performed today then,
                if todaysWorkouts.findLast({$0.name == info.name}) != nil {
                    if todaysWorkouts.count == 1 {
                        // if it's the only workout that should be done today then we have a clear winner.
                        result[index] = ("today", .red)
                    } else if todaysWorkouts.count > 1 {
                        // otherwise we'll tell the user how long it's been so that he can decide.
                        if let last = info.latest {
                            result[index] = (last.friendlyName(), .orange)
                        } else {
                            result[index] = ("never started", .orange)
                        }
                    }
                }
            }
            return result
        }

        // Then we'll check for workouts that can be performed on any day.
        let anyWorkouts = infos.filter({isAnyDay($0.days)})
        if !anyWorkouts.isEmpty {
            for (index, info) in infos.enumerated() {
                // For all the workouts that the user could do today we'll tell the user how long
                // it has been since he has done that workout.
                if anyWorkouts.findLast({$0.name == info.name}) != nil {
                    if let last = info.latest {
                        result[index] = (last.friendlyName(), .orange)
                    } else {
                        result[index] = ("never started", .orange)
                    }
                }
            }
            return result
        }

        // We're at the point where the only workouts that exist are workouts that are scheduled
        // for a day and today is not one of those days. So we'll find the upcoming workout and tell
        // the user when that is due.
        var found = false
        for delta in 1...6 {
            for (index, info) in infos.enumerated() {
                if let candidate = (cal as NSCalendar).date(byAdding: .day, value: delta, to: Date()) {
                    let weekday = cal.component(.weekday, from: candidate)
                    if info.days[weekday - 1] {
                        if delta == 1 {
                            result[index] = ("tomorrow", .blue)
                            found = true
                        } else {
                            result[index] = ("in \(delta) days", .blue)
                            found = true
                        }
                    }
                }
            }
            if found {
                break
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
            Workout("Lower", [burpees(), squats()], day: nil)!,
            Workout("Upper", [planks(), curls()], day: .tuesday)!]
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
