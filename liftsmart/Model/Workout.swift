//  Created by Jesse Vorisek on 5/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

class Workout: CustomDebugStringConvertible, Identifiable {
    var name: String
    var exercises: [Exercise]

    init(_ name: String, _ exercises: [Exercise]) {
        self.name = name
        self.exercises = exercises
    }
    
    var debugDescription: String {
        get {
            return self.name
        }
    }

    var id: String {
        get {
            return self.name
        }
    }
}
