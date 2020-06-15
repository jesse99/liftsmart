//  Created by Jesse Jones on 6/14/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

class History {
    struct Record: CustomDebugStringConvertible {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0
        var label: String       // "3x60s"

        init(_ weight: Double, _ label: String) {
            self.completed = Date()
            self.weight = weight
            self.label = label
        }
        
        var debugDescription: String {
            get {
                return self.completed.description
            }
        }
    }

    var records: [String: [Record]] = [:]   // keyed by formal name, last record is the most recent
    
    // TODO: support user notes?
    func append(_ exercise: Exercise) {
        let record = Record(exercise.current!.weight, exercise.modality.sets.debugDescription)
        self.records[exercise.formalName, default: []].append(record)
    }
}
