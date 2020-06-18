//  Created by Jesse Jones on 6/14/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

class History {
    struct Record: CustomDebugStringConvertible {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0
        var label: String       // "3x60s"

        init(_ date: Date, _ weight: Double, _ label: String) {
            self.completed = date
            self.weight = weight
            self.label = label
        }
        
        var debugDescription: String {
            get {
                return self.completed.description
            }
        }
    }
    
    // TODO: support user notes?
    func append(_ workout: Workout, _ exercise: Exercise) {
        // Using startDate instead of Date() makes testing a bit easier...
        let record = Record(exercise.current!.startDate, exercise.current!.weight, exercise.modality.sets.debugDescription)
        self.records[exercise.formalName, default: []].append(record)
        
        let key = workout.name + "-" + exercise.name
        self.completed[key] = exercise.current!.startDate
    }
    
    func lastCompleted(_ workout: Workout, _ exercise: Exercise) -> Date? {
        let key = workout.name + "-" + exercise.name
        return self.completed[key]
    }
    
    private var records: [String: [Record]] = [:]   // keyed by formal name, last record is the most recent
    private var completed: [String: Date] = [:]  // workout.name + exercise.name => date last completed
}
