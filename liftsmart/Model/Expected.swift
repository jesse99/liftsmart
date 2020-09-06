//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// What the user is expected to do the next time he performs the exercise.
class Expected: CustomDebugStringConvertible, Storable {
    var weight: Double      // may be 0.0
    
    // for maxReps this will have one entry for the total reps the user is expected to do
    // for repRanges this will have entries for each work and backoff set, note that this does override the reps within the set
    var reps: [Int]         // TODO: may want to reset this if user edits reps (that would also help to avoud reps.count and sets.count getting out of sync)

    init(weight: Double, reps: [Int] = []) {        // TODO: should this be failable?
        assert(weight >= 0.0)
        assert(reps.all({$0 > 0}))
        
        self.weight = weight
        self.reps = reps
    }
    
    required init(from store: Store) {
        self.weight = store.getDbl("weight")
        if store.hasKey("reps2") {
            self.reps = store.getIntArray("reps2")
        } else {
            self.reps = []
        }
    }
    
    func save(_ store: Store) {
        store.addDbl("weight", self.weight)
        store.addIntArray("reps2", reps)
    }

    var debugDescription: String {
        get {
            return String(format: "%.3f lbs", self.weight)
        }
    }
}

