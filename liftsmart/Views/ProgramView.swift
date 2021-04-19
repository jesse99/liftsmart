//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

let RecentHours = 8.0

var programEntryId = 0

struct ProgramEntry: Identifiable {
    let id: Int
    let index: Int
    let workout: Workout
    var subLabel = ""           // subLabel and color are initialized using initSubLabels
    var subColor = Color.black

    init(_ workout: Workout, _ index: Int) {
        self.id = programEntryId
        self.index = index
        self.workout = workout
        programEntryId += 1
    }
}

struct ExerciseCompletions {
    let latest: Date?           // date latest exercise was completed
    let latestIsComplete: Bool  // true if all exercises were completed on latest date
    let completedAll: Bool      // true if all exercises were ever completed
}

func initEntries(_ display: Display) -> ([ProgramEntry], [ExerciseCompletions]) {
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
    var entries: [ProgramEntry] = []
    for (index, workout) in display.program.workouts.enumerated() {
        if workout.enabled {
            var dates: [Date] = []
            for exercise in workout.exercises {
                if exercise.enabled {
                    if let completed = exercise.dateCompleted(workout, display.history) {
                        dates.append(completed)
                    }
                }
            }
            dates.sort()

            if let last = dates.last {
                let count = workout.exercises.count {$0.enabled}
                let didAll = dates.count >= count
                completions.append(ExerciseCompletions(latest: last, latestIsComplete: didAll && allOnSameDay(dates), completedAll: didAll))
                entries.append(ProgramEntry(workout, index))

            } else {
                completions.append(ExerciseCompletions(latest: nil, latestIsComplete: false, completedAll: false))
                entries.append(ProgramEntry(workout, index))
            }
        }
    }

    return (entries, completions)
}

// The goal here is to highlight what the user should be doing today or what they should be doing next.
// It's not always possible to do that with exactness but, if that's the case, we'll provide information
// to help them decide what to do.
func initSubLabels(_ history: History, _ completions: [ExerciseCompletions], _ entries: [ProgramEntry], _ now: Date) -> [ProgramEntry] {
    // The workout can be performed on any day.
    func isAnyDay(_ days: [Bool]) -> Bool {
        return days.all({!$0})
    }

    func ageInDays(_ workout: Workout) -> Double {
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

    func nextWorkout(_ entry: ProgramEntry) -> Int? {
        for delta in 1...7 {
            if let candidate = (cal as NSCalendar).date(byAdding: .day, value: delta, to: now) {
                let weekday = cal.component(.weekday, from: candidate)
                if entry.workout.days[weekday - 1] {
                    return delta
                }
            }
        }
        return nil
    }

    let cal = Calendar.current
    let weekday = cal.component(.weekday, from: now)
    let todaysWorkouts = entries.filter({$0.workout.days[weekday - 1]})  // workouts that should be performed today

    var result = entries
    for i in 0..<entries.count {
        var entry = entries[i]
        let completion = completions[i]

        var doneRecently = false
        if let last = completion.latest {
            doneRecently = now.hoursSinceDate(last) <= RecentHours
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
            if completion.latest != nil {
                entry.subLabel = "today"
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
        } else if let delta = nextWorkout(entry) {
            entry.subLabel = delta == 1 ? "tomorrow" : "in \(delta) days"
            if todaysWorkouts.isEmpty && delta == 1 {
                entry.subColor = .blue
            } else {
                entry.subColor = .black
            }
        }

        result[i] = entry
    }

    return result
}

struct ProgramView: View {
    let timer = RestartableTimer(every: TimeInterval.minutes(30)) // subData will change every day so we'll refresh fairly often
    @State var editModal = false
    @State var programsModal = false
    @ObservedObject var display: Display // nicer if this was an EnvironmentObject but then we can't use display from init methods
    
    // Note that View init methods are called quite a bit more often than what one might expect and,
    // in general, they are not called on state changes.
    init(_ display: Display) {
        self.display = display
    }

    // Note that if we create a view here that acts as the root of views with Cancel buttons then
    // we need to be careful init'ing it. See WorkoutView for more.
    var body: some View {
        NavigationView {
            VStack {
                List(self.getEntries()) {entry in
                    NavigationLink(destination: WorkoutView(self.display, entry.index)) {
                        VStack(alignment: .leading) {
                            Text(entry.workout.name).font(.title)
                            Text(entry.subLabel).foregroundColor(entry.subColor).font(.headline) // 10+ Reps or As Many Reps As Possible
                        }
                    }
                }
                .navigationBarTitle(Text(self.display.program.name + " Workouts" + self.display.edited))
                .onAppear {self.timer.restart(); self.display.send(.TimePassed)}
                .onDisappear {self.timer.stop()}
                .onReceive(self.timer.timer) {_ in self.display.send(.TimePassed)}

                Divider()
                HStack {
                    // Would be nice to make this a tab but then switching programs completely hoses all
                    // existing views.
                    Button("Programs", action: onPrograms)
                        .font(.callout).labelStyle(/*@START_MENU_TOKEN@*/DefaultLabelStyle()/*@END_MENU_TOKEN@*/)
                        .sheet(isPresented: self.$programsModal) {ProgramsView(self.display)}
                    Spacer()
                    Button("Edit", action: onEdit)
                        .font(.callout).labelStyle(/*@START_MENU_TOKEN@*/DefaultLabelStyle()/*@END_MENU_TOKEN@*/)
                        .sheet(isPresented: self.$editModal) {EditProgramView(self.display)}
                }
                .padding()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
    
    private func getEntries() -> [ProgramEntry] {
        let (entries, completions) = initEntries(display)
        return initSubLabels(display.history, completions, entries, Date())
    }
    
    private func onEdit() {
        self.editModal = true
    }
    
    private func onPrograms() {
        self.programsModal = true
    }
}

func previewDisplay() -> Display {
    func previewHistory(_ program: Program) -> History {
        let history = History()
        history.append(program.workouts[0], program.workouts[0].exercises[0])
        history.append(program.workouts[1], program.workouts[1].exercises[0])

        // This stuff is for HistoryView.
        let exercise = program.workouts[0].exercises.first(where: {$0.name == "Curls"})!
        exercise.current = Current(weight: 0.0)
        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        exercise.current!.setIndex = 1
        exercise.current!.actualReps = ["5 reps", "5 reps", "5 reps"]
        exercise.current!.actualPercents = []
        history.append(program.workouts[0], exercise)

        exercise.current!.weight = 135.0
        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        exercise.current!.actualPercents = [1.0, 1.0, 1.0]
        history.append(program.workouts[0], exercise)

        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        exercise.current!.actualReps = ["5 reps", "5 reps", "3 reps"]
        exercise.current!.actualPercents = [1.0, 1.0, 1.0]
        history.append(program.workouts[0], exercise)

        exercise.current?.startDate = Date()
        exercise.current = Current(weight: 135.0)
        exercise.current!.actualReps = ["5 reps", "3 reps", "1 reps"]
        exercise.current!.actualPercents = [0.70, 0.8, 0.9]
        let record = history.append(program.workouts[0], exercise)
        record.note = "Felt strong!"

        return history
    }
    
    func previewProgram() -> Program {
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
            let warmup = RepsSet(reps: RepRange(4), percent: WeightPercent(0.0), restSecs: 90)
            let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60)
            let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
//            let modality = Modality(Apparatus.bodyWeight, sets)
            let modality = Modality(Apparatus.fixedWeights(name: "Dumbbells"), sets)
            return Exercise("Split Squat", "Dumbbell Single Leg Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
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
        
        func pullups() -> Exercise {
            let sets = Sets.repTarget(target: 15, rest: 120)
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Pullups", "Pullups", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        func formRolling() -> Exercise {
            let work = RepsSet(reps: RepRange(15), restSecs: 0)
            let sets = Sets.fixedReps([work])
            let modality = Modality(Apparatus.bodyWeight, sets)
            return Exercise("Foam Rolling", "IT-Band Foam Roll", modality)
        }

        let workouts = [
            createWorkout("Temp1", [planks(), curls(), formRolling(), pullups()], day: .friday).unwrap(),
            createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap(),
            createWorkout("Lower", [burpees(), squats()], day: .wednesday).unwrap(),
            createWorkout("Upper", [planks(), curls()], day: .monday).unwrap()]
        return Program("Split", workouts)
    }

    let program = previewProgram()
    let weights: [String: FixedWeightSet] = ["Dumbbells": FixedWeightSet([5.0, 20.0, 10.0, 15.0]), "Kettlebells": FixedWeightSet([10.0, 20.0, 30.0])]
    let programs = [
        program.name: program.name,
        "GZCLP": "GZCLP",
        "Texas Method": "Texas Method",
        "Strong Curves": "Strong Curves",
        "Boring But Big": "Boring But Big"]
    return Display(program, previewHistory(program), weights, programs)
}

struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(previewDisplay())
    }
}
