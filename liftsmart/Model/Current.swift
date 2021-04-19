//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// Where the user is now with respect to an Exercise. Unlike Workouts this is information that
/// is expected to regularly change.
final class Current: CustomDebugStringConvertible, Storable {
    var startDate: Date          // date exercise was started
    var weight: Double           // may be 0.0, this is from expected.weight
    var setIndex: Int            // if this is sets.count then the user has finished those sets
    var actualReps: [String]     // what the user has done so far, e.g. ["5", "3", "1"] or ["60s", "60s"]
    var actualPercents: [Double] // empty for 100% of weight or [0.7, 0.8, 0.9]
    
    // durations: not used
    // fixed reps: number of reps the user has done so far
    // max reps: total number of reps the user has done so far (only one value)
    // rep ranges: number of reps the user has done so far (not counting warmup)
    // rep target: number of reps the user has done so far
    var completed: [Int]

    init(weight: Double) {
        self.startDate = Date()
        self.weight = weight
        self.setIndex = 0
        self.actualReps = []
        self.actualPercents = []
        self.completed = []
    }
    
    init(from store: Store) {
        self.startDate = store.getDate("startDate")
        self.weight = store.getDbl("weight")
        self.setIndex = store.getInt("setIndex")
        if store.hasKey("actualReps") {
            self.actualReps = store.getStrArray("actualReps")
        } else {
            self.actualReps = []
        }
        if store.hasKey("actualPercents") {
            self.actualPercents = store.getDblArray("actualPercents")
        } else {
            self.actualPercents = []
        }
        if store.hasKey("completed") {
            self.completed = store.getIntArray("completed")
        } else {
            self.completed = []
        }
    }
    
    func save(_ store: Store) {
        store.addDate("startDate", startDate)
        store.addDbl("weight", weight)
        store.addInt("setIndex", setIndex)
        store.addStrArray("actualReps", actualReps)
        store.addDblArray("actualPercents", actualPercents)
        store.addIntArray("completed", completed)
    }

    var debugDescription: String {
        get {
            return "on set \(self.setIndex)"
        }
    }
}
