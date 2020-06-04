//  Created by Jesse Vorisek on 5/10/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// Defines how an exercise should be performed and what to do after completing the exercise.
/// In general all modality combinations make sense. The only exception I can think of is
/// untimed sets with progression.
class Modality: CustomDebugStringConvertible {
    var apparatus: Apparatus
    var sets: Sets
//    var progression: Progression?
//    var advisor: Advisor?
    
    init(_ apparatus: Apparatus, _ sets: Sets) {
        self.apparatus = apparatus
        self.sets = sets
    }
    
    var debugDescription: String {
        get {
            return sets.debugDescription
        }
    }
}
