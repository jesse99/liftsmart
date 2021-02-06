//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var programEntryId = 0

struct ProgramEntry: Identifiable {
    let id: Int
    let workout: Workout
    var subLabel = ""           // subLabel and color are initialized using a second pass
    var subColor = Color.black

    init(_ workout: Workout) {
        self.id = programEntryId
        self.workout = workout
        programEntryId += 1
    }
}

struct ProgramView: View {
    var program: Program
    var history: History
    let timer = RestartableTimer(every: TimeInterval.minutes(30))
    @State var entries: [ProgramEntry] = []
    @State var editModal = false

    init(program: Program, history: History) {
        self.program = program
        self.history = history
        self.refresh()
    }

    var body: some View {
        NavigationView {
            VStack {
                List(self.entries) {entry in
                    NavigationLink(destination: WorkoutView(workout: entry.workout, history: self.history)) {
                        VStack(alignment: .leading) {
                            Text(entry.workout.name).font(.title)
                            Text(entry.subLabel).foregroundColor(entry.subColor).font(.headline) // 10+ Reps or As Many Reps As Possible
                        }
                    }
                }
                .navigationBarTitle(Text(program.name + " Workouts"))
                .onAppear {self.refresh(); self.timer.restart()}
                .onDisappear {self.timer.stop()}
                .onReceive(self.timer.timer) {_ in self.refresh()}
                
                Divider()
                HStack {
                    Spacer()
                    Button("Edit", action: onEdit)
                        .font(.callout)
                        .sheet(isPresented: self.$editModal, onDismiss: self.refresh) {EditProgramView(program: self.program)}
                }
                .padding()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
    
    private func onEdit() {
        self.editModal = true
    }

    // subData will change every day so we use a timer to refresh the UI in case the user has been sitting
    // on this view for a long time.
    func refresh() {
        struct ExerciseCompletions {
            let latest: Date?           // date latest exercise was completed
            let latestIsComplete: Bool  // true if all exercises were completed on latest date
            let completedAll: Bool      // true if all exercises were ever completed
        }

        func initEntries() -> [ExerciseCompletions] {
            func allOnSameDay(_ dates: [Date]) -> Bool {
                let calendar = Calendar.current
                for date in dates {
                    if !calendar.isDate(date, inSameDayAs: dates[0]) {
                        return false
                    }
                }
                return true
            }
                    
            var completions: [ExerciseCompletions] = []
            entries = []
            for workout in program {
                if workout.enabled {
                    var dates: [Date] = []
                    for exercise in workout.exercises {
                        if exercise.enabled {
                            if let completed = exercise.dateCompleted(workout, history) {
                                dates.append(completed)
                            }
                        }
                    }
                    dates.sort()
                    
                    if let last = dates.last {
                        let count = workout.exercises.count {$0.enabled}
                        let didAll = dates.count >= count
                        completions.append(ExerciseCompletions(latest: last, latestIsComplete: didAll && allOnSameDay(dates), completedAll: didAll))
                        entries.append(ProgramEntry(workout))

                    } else {
                        completions.append(ExerciseCompletions(latest: nil, latestIsComplete: false, completedAll: false))
                        entries.append(ProgramEntry(workout))
                    }
                }
            }
            
            return completions
        }
        
        // The goal here is to highlight what the user should be doing today or what they should be doing next.
        // It's not always possible to do that with exactness but, if that's the case, we'll provide information
        // to help them decide what to do.
        func initSubLabels(_ completions: [ExerciseCompletions]) {
            // The workout can be performed on any day.
            func isAnyDay(_ days: [Bool]) -> Bool {
                return days.all({!$0})
            }
            
            func ageInDays(_ workout: Workout) -> Double {
                let now = Date()
                if let completed = workout.dateCompleted(history) {
                    return now.daysSinceDate(completed.0)
                } else {
                    // If the workout has never been completed then we'll just use a really old date
                    // so that we can avoid special casing.
                    return now.daysSinceDate(Date(timeIntervalSinceReferenceDate: 0))
                }
            }

            func oldestWorkout(_ entries: [ProgramEntry]) -> Workout? {
                let oldest = entries.max { (lhs, rhs) -> Bool in
                    return ageInDays(lhs.workout) < ageInDays(rhs.workout)
                }
                return oldest != nil ? oldest?.workout : nil
            }
            
            func agesMatch(_ oldest: Workout, _ workout: Workout) -> Bool {
                return abs(ageInDays(oldest) - ageInDays(workout)) <= 0.3   // same day if they are within +/- 8 hours (for those whackos who workout through midnight)
            }

            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: Date())
            let todaysWorkouts = entries.filter({$0.workout.days[weekday - 1]})  // workouts that should be performed today
            var nextWorkout: (Int, Int)? = nil
            for delta in 1...13 {
                for entry in entries {
                    if nextWorkout == nil {
                        if let candidate = (cal as NSCalendar).date(byAdding: .day, value: delta, to: Date()) {
                            let weekday = cal.component(.weekday, from: candidate)
                            if entry.workout.days[weekday - 1] {
                                nextWorkout = (weekday, delta)              // next workout scheduled after today
                            }
                        }
                    }
                }
            }

            for i in 0..<entries.count {
                var entry = entries[i]
                let completion = completions[i]
                
                var doneRecently = false
                if let last = completion.latest {
                    doneRecently = Date().hoursSinceDate(last) < 4
                }
                
                // If the user has done any exercise within the workout today,
                if doneRecently {
                    if completion.latestIsComplete {
                        // and they completed every exercise.
                        entry.subLabel = "completed"

                    } else {
                        // there are exercises within the workout that they haven't done.
                        entry.subLabel = "in progress"
                        entry.subColor = .red
                    }
                
                // If the workout can be performed on any day (including days on which other workouts are scheduled),
                } else if isAnyDay(entry.workout.days) {
                    if let last = completion.latest {
                        entry.subLabel = last.friendlyName()
                    } else {
                        entry.subLabel = "never started"
                    }
                    entry.subColor = .orange

                // If the workout is scheduled for today,
                } else if todaysWorkouts.findLast({$0.workout.name == entry.workout.name}) != nil {
                    if let oldest = oldestWorkout(todaysWorkouts) {
                        entry.subLabel = "today"
                        if agesMatch(oldest, entry.workout) {
                            entry.subColor = .red
                        } else {
                            entry.subColor = .orange
                        }
                    } else {
                        entry.subLabel = "never started"
                        entry.subColor = .orange
                    }
                    
                // If the workout is scheduled for later.
                } else if let (weekday, delta) = nextWorkout, (entry.workout.days[weekday - 1]) {
                    entry.subLabel = delta == 1 ? "tomorrow" : "in \(delta) days"
                    entry.subColor = .blue
                }
                
                entries[i] = entry
            }
        }

        let completions = initEntries()
        initSubLabels(completions)
    }
}

struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(program: ProgramView_Previews.home(), history: ProgramView_Previews.history())
    }
    
    private static func home() -> Program {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func planks() -> Exercise { // TODO: this should be some sort of progression
            let durations = [
                DurationSet(secs: 60, restSecs: 90),
                DurationSet(secs: 60, restSecs: 90),
                DurationSet(secs: 60, restSecs: 90)]
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
            let e = Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: [65]))
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        let workouts = [
            createWorkout("Temp1", [planks(), curls()], day: .friday).unwrap(),
            createWorkout("Temp2", [squats()], day: .friday).unwrap(),
            createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap(),
            createWorkout("Lower", [burpees(), squats()], day: .wednesday).unwrap(),
            createWorkout("Upper", [planks(), curls()], day: .monday).unwrap()]
        return Program("Split", workouts)
    }

    private static func history() -> History {
        let program = ProgramView_Previews.home()
        let history = History()
        history.append(program[0], program[0].exercises[0])
        history.append(program[0], program[0].exercises[1])
        history.append(program[1], program[1].exercises[0])
        return history
    }
}
