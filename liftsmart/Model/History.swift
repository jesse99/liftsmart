//  Created by Jesse Jones on 6/14/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

class History: Storable {
    class Record: CustomDebugStringConvertible, Storable {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0, this is from current.weight
        var reps: [String]      // ["5", "3", "1"] or ["60s", "60s"]
        var percents: [Double]  // empty for 100% of weight or [0.7, 0.8, 0.9]
        var key: String         // exercise.name + workout.name
        var note: String = ""   // optional arbitrary text set by user

        init(_ date: Date, _ weight: Double, _ reps: [String], _ percents: [Double], _ key: String) {
            self.completed = date
            self.weight = weight
            self.reps = reps
            self.percents = percents
            self.key = key
        }
        
        required init(from store: Store) {
            self.completed = store.getDate("completed")
            self.weight = store.getDbl("weight")
            if store.hasKey("reps") {
                self.reps = store.getStrArray("reps")
                self.percents = store.getDblArray("percents")
            } else {
                self.reps = [store.getStr("label")]
                self.percents = []
            }
            self.key = store.getStr("key", ifMissing: "")
            self.note = store.getStr("note", ifMissing: "")
        }
        
        func save(_ store: Store) {
            store.addDate("completed", completed)
            store.addDbl("weight", weight)
            store.addStrArray("reps", reps)
            store.addDblArray("percents", percents)
            store.addStr("key", key)
            store.addStr("note", note)
        }

        var label: String {
            get {
                if percents.all({$0 == 1.0}) {
                    return dedupe(reps).joined(separator: ", ") + self.suffix(1.0)
                }

                if percents.all({$0 == percents[0]}) {
                    return dedupe(reps).joined(separator: ", ") + self.suffix(percents[0])
                }
                
                var actual: [String] = []
                for i in 0..<reps.count {
                    actual.append(reps[i] + self.suffix(percents[i]))
                }
                
                return dedupe(actual).joined(separator: ", ")
            }
        }

        var debugDescription: String {
            get {
                return self.completed.description
            }
        }
        
        private func suffix(_ percent: Double) -> String {
            let w = weight*percent
            if w >= 0.01 {
                return " @ " + friendlyUnitsWeight(w)
            } else {
                return ""
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
        // Using startDate instead of Date() makes testing a bit easier...
        let key = workout.name + "-" + exercise.name
        let record = Record(exercise.current!.startDate, exercise.current!.weight, exercise.current!.actualReps, exercise.current!.actualPercents, key)
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
                ASSERT(false, "couldn't find record for \(exercise.formalName)")
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
