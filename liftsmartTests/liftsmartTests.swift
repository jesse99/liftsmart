//  Created by Jesse Jones on 4/18/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import XCTest
@testable import liftsmart

class liftsmartTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // Scheduled are the days that the workout is scheduled for relative to today.
    // So [0] means it's scheduled for the current weekday.
    // And [1, 3] means that it is scheduled for tomorrow and again 3 days from the current date.
    func weekdays(_ now: Date, _ scheduled: [Int]) -> [WeekDay] {
        var days: [WeekDay] = []
        
        for delta in scheduled {
            let d = Calendar.current.date(byAdding: .day, value: delta, to: now)!
            let weekday = Calendar.current.component(.weekday, from: d)
            days.append(WeekDay(rawValue: weekday - 1)!)
        }
        
        return days
    }

    // ages are in hours
    func getEntries(age0: Int?, age1: Int?, scheduled: [Int]) -> ProgramEntry {
        let now = Date()
        let curls = Exercise("Curls", "Hammer Curls", Modality(Apparatus.bodyWeight, Sets.maxReps(restSecs: [90])))
        let pullups = Exercise("Pullup", "Pullup", Modality(Apparatus.bodyWeight, Sets.maxReps(restSecs: [90])))
        let workout = createWorkout("Workout", [curls, pullups], days: weekdays(now, scheduled)).unwrap()

        history = History()
        if let age = age0 {
            curls.current = Current(weight: 0.0)
            curls.current?.startDate = Calendar.current.date(byAdding: .hour, value: -age, to: now)!
            history.append(workout, curls)
        }
        if let age = age1 {
            pullups.current = Current(weight: 0.0)
            pullups.current?.startDate = Calendar.current.date(byAdding: .hour, value: -age, to: now)!
            history.append(workout, pullups)
        }

        let program = Program("Program", [workout])
        let (entries, completions) = initEntries(program)
        XCTAssertEqual(entries.count, 1)    // one workout so one entry

        return initSubLabels(completions, entries, now)[0]
    }

    func testProgramLabels() throws {
        // no history
        var entry = getEntries(age0: nil, age1: nil, scheduled: [])
        XCTAssertEqual(entry.subLabel, "never started")

        entry = getEntries(age0: nil, age1: nil, scheduled: [0])
        XCTAssertEqual(entry.subLabel, "today")

        entry = getEntries(age0: nil, age1: nil, scheduled: [-1])
        XCTAssertEqual(entry.subLabel, "in 6 days")

        entry = getEntries(age0: nil, age1: nil, scheduled: [-2])
        XCTAssertEqual(entry.subLabel, "in 5 days")

        entry = getEntries(age0: nil, age1: nil, scheduled: [1])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: nil, age1: nil, scheduled: [2])
        XCTAssertEqual(entry.subLabel, "in 2 days")
        
        // really old history
        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [])
        XCTAssertEqual(entry.subLabel, "today")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [0])
        XCTAssertEqual(entry.subLabel, "today")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [-1])
        XCTAssertEqual(entry.subLabel, "in 6 days")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [-2])
        XCTAssertEqual(entry.subLabel, "in 5 days")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [1])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [2])
        XCTAssertEqual(entry.subLabel, "in 2 days")

        // no history and multiple scheduled
        entry = getEntries(age0: nil, age1: nil, scheduled: [0, 2, 4])
        XCTAssertEqual(entry.subLabel, "today")

        entry = getEntries(age0: nil, age1: nil, scheduled: [1, 3, 5])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: nil, age1: nil, scheduled: [2, 4, 6])
        XCTAssertEqual(entry.subLabel, "in 2 days")

        // really old history and multiple scheduled
        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [0, 2, 4])
        XCTAssertEqual(entry.subLabel, "today")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [1, 3, 5])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: 30*24, age1: 29*24, scheduled: [2, 4, 6])
        XCTAssertEqual(entry.subLabel, "in 2 days")

        // completed today
        entry = getEntries(age0: 1, age1: 1, scheduled: [])
        XCTAssertEqual(entry.subLabel, "completed")

        entry = getEntries(age0: 1, age1: 1, scheduled: [0])
        XCTAssertEqual(entry.subLabel, "completed")

        entry = getEntries(age0: 1, age1: 1, scheduled: [-1])    // odd case
        XCTAssertEqual(entry.subLabel, "completed")

        entry = getEntries(age0: 1, age1: 1, scheduled: [1])     // odd case
        XCTAssertEqual(entry.subLabel, "completed")

        entry = getEntries(age0: 5, age1: 5, scheduled: [1])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: 5, age1: 5, scheduled: [2])
        XCTAssertEqual(entry.subLabel, "in 2 days")
        
        // partially completed
        entry = getEntries(age0: 1, age1: nil, scheduled: [])
        XCTAssertEqual(entry.subLabel, "in progress")

        entry = getEntries(age0: 1, age1: nil, scheduled: [0])
        XCTAssertEqual(entry.subLabel, "in progress")

        entry = getEntries(age0: 1, age1: nil, scheduled: [-1])    // odd case
        XCTAssertEqual(entry.subLabel, "in progress")

        entry = getEntries(age0: 1, age1: nil, scheduled: [1])     // odd case
        XCTAssertEqual(entry.subLabel, "in progress")

        entry = getEntries(age0: 5, age1: nil, scheduled: [1])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: 5, age1: nil, scheduled: [2])
        XCTAssertEqual(entry.subLabel, "in 2 days")

        // days
        entry = getEntries(age0: 3*24, age1: 2*24, scheduled: [0, 2])
        XCTAssertEqual(entry.subLabel, "today")

        entry = getEntries(age0: 3*24, age1: 2*24, scheduled: [1, 3])
        XCTAssertEqual(entry.subLabel, "tomorrow")

        entry = getEntries(age0: 3*24, age1: 2*24, scheduled: [2, 5])
        XCTAssertEqual(entry.subLabel, "in 2 days")
    }
}
