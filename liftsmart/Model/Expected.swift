//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// What the user is expected to do the next time he performs the exercise.
class Expected: CustomDebugStringConvertible, Storable {
    var weight: Double      // may be 0.0
    var reps: Int?          // set for Sets.repsRanges, indicates where the user is within a variable reps set, can also override fixed reps

    init(weight: Double, reps: Int? = nil) {        // TODO: should this be failable?
        assert(weight >= 0.0)
        assert(reps == nil || reps! > 0)
        
        self.weight = weight
        self.reps = reps
    }
    
    required init(from store: Store) {
        self.weight = store.getDbl("weight")
        if store.hasKey("reps") {
            self.reps = store.getInt("reps")
        } else {
            self.reps = nil
        }
    }
    
    func save(_ store: Store) {
        store.addDbl("weight", self.weight)
        if let reps = self.reps {
            store.addInt("reps", reps)
        }
    }

    var debugDescription: String {
        get {
            return String(format: "%.3f lbs", self.weight)
        }
    }
}
