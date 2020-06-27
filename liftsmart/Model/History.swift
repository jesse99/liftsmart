//  Created by Jesse Jones on 6/14/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

class History: Storable {
    struct Record: CustomDebugStringConvertible, Storable {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0
        var label: String       // "3x60s"

        init(_ date: Date, _ weight: Double, _ label: String) {
            self.completed = date
            self.weight = weight
            self.label = label
        }
        
        init(from store: Store) {
            self.completed = store.getDate("completed")
            self.weight = store.getDbl("weight")
            self.label = store.getStr("label")
        }
        
        func save(_ store: Store) {
            store.addDate("completed", completed)
            store.addDbl("weight", weight)
            store.addStr("label", label)
        }

        var debugDescription: String {
            get {
                return self.completed.description
            }
        }
    }
    
    init() {
    }
    
    required init(from store: Store) {
        self.records = [:]
        self.completed = [:]
        
        let keys1 = store.getStrArray("record-keys")
        for (i, key) in keys1.enumerated() {
            let values: [Record] = store.getObjArray("record-value-\(i)")
            self.records[key] = values
        }

        let keys2 = store.getStrArray("completed-keys")
        let values2 = store.getDateArray("completed-values")
        for (i, key) in keys2.enumerated() {
            self.completed[key] = values2[i]
        }
    }
    
    func save(_ store: Store) {
        let keys1 = Array(records.keys)
        store.addStrArray("record-keys", keys1)
        for (i, key) in keys1.enumerated() {                   // note that we have to iterate over these in keys order
            store.addObjArray("record-value-\(i)", records[key]!)
        }
        
        let keys2 = Array(completed.keys)
        let values = Array(completed.values)
        store.addStrArray("completed-keys", keys2)
        store.addDateArray("completed-values", values)
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
