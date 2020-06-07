//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// Where the user is now with respect to an Exercise. Unlike Workouts this is information that
/// is expected to regularly change.
class Current: CustomDebugStringConvertible {
    var date: Date          // if setIndex == sets.count then this is date exercise was finished otherwise date exercise was started
    var weight: Double      // may be 0.0
    var setIndex: Int       // if this is sets.count then the user has finished those sets

    init(weight: Double) {
        self.date = Date()
        self.weight = weight
        self.setIndex = 0
    }
    
    var debugDescription: String {
        get {
            return "on set \(self.setIndex)"
        }
    }
}
