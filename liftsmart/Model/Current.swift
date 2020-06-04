//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// Where the user is now with respect to an Exercise. Unlike Workouts this is information that
/// is expected to regularly change.
class Current: CustomDebugStringConvertible {
    var date: Date          // when the user last performed the exercise
    var weight: Double      // may be 0.0
    var setIndex: Int       

    init(weight: Double) {
        self.date = Date()
        self.weight = weight
        self.setIndex = 0
    }
    
    var debugDescription: String {
        get {
            return "set \(self.setIndex)"
        }
    }
}
