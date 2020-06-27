//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// Where the user is now with respect to an Exercise. Unlike Workouts this is information that
/// is expected to regularly change.
final class Current: CustomDebugStringConvertible, Storable {
    var startDate: Date     // date exercise was started
    var weight: Double      // may be 0.0
    var setIndex: Int       // if this is sets.count then the user has finished those sets

    init(weight: Double) {
        self.startDate = Date()
        self.weight = weight
        self.setIndex = 0
    }
    
    init(from store: Store) {
        self.startDate = store.getDate("startDate")
        self.weight = store.getDbl("weight")
        self.setIndex = store.getInt("setIndex")
    }
    
    func save(_ store: Store) {
        store.addDate("startDate", startDate)
        store.addDbl("weight", weight)
        store.addInt("setIndex", setIndex)
    }
    
    var debugDescription: String {
        get {
            return "on set \(self.setIndex)"
        }
    }
}
