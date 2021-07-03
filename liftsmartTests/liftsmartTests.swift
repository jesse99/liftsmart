//  Created by Jesse Jones on 4/18/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI
import XCTest
@testable import liftsmart

class liftsmartTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // Upper on Monday and Friday. Lower on Thursday.
    func testBasicLabels() throws {
        program = createProgram()
        history = History()
        display = Display(program, history)
        
        resetDate() // sun, mon, tues, wed, thurs
        XCTAssertEqual(actual(), "Upper/tomorrow/blue••Lower/in 4 days/black")

        advanceTo(.monday) // mon, tues, wed, thurs
        XCTAssertEqual(actual(), "Upper/today/red••Lower/in 3 days/black")

        complete("Upper", "Curls")
        XCTAssertEqual(actual(), "Upper/completed/black••Lower/in 3 days/black")
        
        // TODO: could also test in progress
    }

    // Upper on Monday and Friday on week 1.
    // Lower on Thursday on week 2.
    // Rest on week 3.
    func testWeeklyLabels() throws {
        program = createProgram()

        let upper = program.workouts.first(where: {$0.name == "Upper"})!
        upper.weeks = [1]
        let lower = program.workouts.first(where: {$0.name == "Lower"})!
        lower.weeks = [2]
        let rest = Workout("Rest", [], days: [], weeks: [3])
        program.workouts.append(rest)

        history = History()
        display = Display(program, history)
        
        resetDate() // sun week 1
        let epoch = overrideNow!
        printDate(epoch)
        XCTAssertEqual(actual(), "Upper/tomorrow/blue••Lower/in 11 days/black••Rest/in 14 days/black")

        advanceTo(.monday) // week 1
        XCTAssertEqual(actual(), "Upper/today/red••Lower/in 10 days/black••Rest/in 13 days/black")

        complete("Upper", "Curls")
        XCTAssertEqual(actual(), "Upper/completed/black••Lower/in 10 days/black••Rest/in 13 days/black")
        
        advanceTo(.friday) // week 1
        XCTAssertEqual(actual(), "Upper/today/red••Lower/in 6 days/black••Rest/in 9 days/black")

        complete("Upper", "Curls")
        XCTAssertEqual(actual(), "Upper/completed/black••Lower/in 6 days/black••Rest/in 9 days/black")

        advanceTo(.thursday) // week 2
        XCTAssertEqual(actual(), "Upper/in 11 days/black••Lower/today/red••Rest/in 3 days/black")

        advanceTo(.saturday) // week 2
        XCTAssertEqual(actual(), "Upper/in 9 days/black••Lower/in 19 days/black••Rest/tomorrow/blue")

        advanceTo(.sunday) // week 3
        XCTAssertEqual(actual(), "Upper/in 8 days/black••Lower/in 18 days/black••Rest/today/orange")

        advanceTo(.monday) // week 3
        XCTAssertEqual(actual(), "Upper/in 7 days/black••Lower/in 17 days/black••Rest/today/orange")

        advanceTo(.sunday) // week 1
        XCTAssertEqual(actual(), "Upper/tomorrow/blue••Lower/in 11 days/black••Rest/in 14 days/black")

        // TODO: what happens if complete week 2 workout first?
        // TODO: what happens if we do week 2 and then week 1?
        // TODO: what if there is no week 1?
        // TODO: what if there is no week 2?
    }
    
    private func createProgram() -> Program {
        let sets = Sets.maxReps(restSecs: [90, 90, 0])
        let modality = Modality(Apparatus.bodyWeight, sets)
        let curls = Exercise("Curls", "Hammer Curls", modality)
        let upper = Workout("Upper", [curls], days: [.monday, .friday])

        let squats = Exercise("Squats", "Dumbbell Single Leg Split Squat", modality)
        let lower = Workout("Lower", [squats], days: [.thursday])
        
        let program = Program("Test", [upper, lower])
        return program
    }
    
    private func complete(_ workoutName: String, _ exerciseName: String) {
        let workout = program.workouts.first(where: {$0.name == workoutName})!
        let exercise = workout.exercises.first(where: {$0.name == exerciseName})!
        exercise.current = Current(weight: 0.0)
        exercise.current!.startDate = overrideNow!

        display.send(.AppendHistory(workout, exercise))
        overrideNow = Calendar.current.date(byAdding: .minute, value: 1, to: overrideNow!)!  // make sure time has advanced a little bit
    }
    
    // For the sake of consistency we'll start all dates from this point.
    private func resetDate() {
        let calendar = Calendar.current
        let components = DateComponents(calendar: calendar, year: 2021, month: 5, day: 2)   // sunday
        overrideNow = calendar.date(from: components)!
    }
    
    private func advanceTo(_ day: WeekDay) {
        while true {
            overrideNow = Calendar.current.date(byAdding: .day, value: 1, to: overrideNow!)!
            let weekday = Calendar.current.component(.weekday, from: overrideNow!)  // 1 based, sunday is first
            if weekday - 1 == day.rawValue {
                printDate(overrideNow!)
                break
            }
        }
    }
    
    private func printDate(_ date: Date) {
//        let dateFormatterPrint = DateFormatter()
//        dateFormatterPrint.dateFormat = "EEEE, MMM d, yyyy"
//
//        let time = dateFormatterPrint.string(from: date)
//        let week = Calendar.current.component(.weekOfYear, from: overrideNow!)
//        print("\(time) week=\(week)")
    }

    private struct Label: CustomStringConvertible {
        let workout: String       // Upper, Lower, etc
        var subLabel: String      // in progress, today, in 3 days, etc
        var subColor: Color       // red, orange, black
        
        init(_ w: String, _ s: String, _ c: Color) {
            workout = w
            subLabel = s
            subColor = c
        }
    
        public var description: String {
            return "\(workout)/\(subLabel)/\(subColor)"
        }
    }

    private func actual() -> String {
        let (entries2, completions) = initEntries(display)
        let entries = initSubLabels(display, completions, entries2)
        let labels = entries.map({Label($0.workout.name, $0.subLabel, $0.subColor).description})
        return labels.joined(separator: "••")
    }
    
    private var program: Program!
    private var history: History!
    private var display: Display!
}
