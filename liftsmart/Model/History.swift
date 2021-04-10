//  Created by Jesse Jones on 6/14/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

class History: Storable {
    class Record: CustomDebugStringConvertible, Storable {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0
        var label: String       // "3x60s" includes weight if that was used
        var key: String         // exercise.name + workout.name
        var note: String = ""   // optional arbitrary text set by user

        init(_ date: Date, _ weight: Double, _ label: String, _ key: String) {
            self.completed = date
            self.weight = weight
            self.label = label
            self.key = key
        }
        
        required init(from store: Store) {
            self.completed = store.getDate("completed")
            self.weight = store.getDbl("weight")
            self.label = store.getStr("label")
            self.key = store.getStr("key", ifMissing: "")
            self.note = store.getStr("note", ifMissing: "")
        }
        
        func save(_ store: Store) {
            store.addDate("completed", completed)
            store.addDbl("weight", weight)
            store.addStr("label", label)
            store.addStr("key", key)
            store.addStr("note", note)
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
    
    func clone() -> History {
        let store = Store()
        store.addObj("self", self)
        let result: History = store.getObj("self")
        return result
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

    @discardableResult func append(_ workout: Workout, _ exercise: Exercise) -> History.Record {
        func getActual(_ current: Current) -> String {
            if current.actualWeights.all({$0 == ""}) {
                return dedupe(current.actualReps).joined(separator: ", ")
            }

            if current.actualWeights.all({$0 == current.actualWeights[0]}) {
                return dedupe(current.actualReps).joined(separator: ", ") + " @ " + current.actualWeights[0]
            }
            
            var actual: [String] = []
            for i in 0..<current.actualReps.count {
                if i < current.actualWeights.count && current.actualWeights[i] != "" {
                    actual.append("\(current.actualReps[i]) @ \(current.actualWeights[i])")
                } else {
                    actual.append(current.actualReps[i])
                }
            }
            
            return dedupe(actual).joined(separator: ", ")
        }
        
        // Using startDate instead of Date() makes testing a bit easier...
        let key = workout.name + "-" + exercise.name
        let actual = getActual(exercise.current!)
        let record = Record(exercise.current!.startDate, exercise.current!.weight, actual, key)
        self.records[exercise.formalName, default: []].append(record)
        self.completed[key] = exercise.current!.startDate
        return record
    }
    
    func delete(_ workout: Workout, _ exercise: Exercise, _ record: History.Record) {
        if var records = self.records[exercise.formalName] {
            if let index = records.firstIndex(where: {$0 === record}) {
                records.remove(at: index)
                self.records[exercise.formalName] = records
                
                if index >= records.count {
                    let key = workout.name + "-" + exercise.name
                    if let last = records.last {
                        self.completed[key] = last.completed
                    } else {
                        self.completed[key] = nil
                    }
                }
            } else {
                assert(false)
            }
        }
    }
    
    func deleteAll(_ workout: Workout, _ exercise: Exercise) {
        if var records = self.records[exercise.formalName] {
            records.removeAll()
            self.records[exercise.formalName] = records

            let key = workout.name + "-" + exercise.name
            self.completed[key] = nil
        }
    }
    
    func lastCompleted(_ workout: Workout, _ exercise: Exercise) -> Date? {
        let key = workout.name + "-" + exercise.name
        return self.completed[key]
    }
    
    // These are oldest to newest.
    func exercise(_ workout: Workout, _ exercise: Exercise) -> RecordSequence {
        return History.RecordSequence(history: self, workout: workout, exercise: exercise)
    }
    
    struct RecordSequence: Sequence {
        let history: History
        let workout: Workout
        let exercise: Exercise
        
        func makeIterator() -> History.RecordSequence.Iterator {
            let key = workout.name + "-" + exercise.name
            return History.RecordSequence.Iterator(history: self.history, formalName: self.exercise.formalName, key: key)
        }
        
        struct Iterator: IteratorProtocol {
            let history: History
            let formalName: String
            let key: String
            var index: Int = 0
            
            mutating func next() -> Record? {
                let entries = history.records[formalName] ?? []
                while index < entries.count {
                    let result = entries[index]
                    index += 1
                    if result.key == key {
                        return result
                    }
                }
                return nil
            }
        }
    }

    private var records: [String: [Record]] = [:]   // keyed by formal name, last record is the most recent
    private var completed: [String: Date] = [:]  // workout.name + exercise.name => date last completed
}
