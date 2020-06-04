//  Created by Jesse Vorisek on 5/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

var nextID: Int = 0     // TODO: need to persist this

/// An Exercise all the details for how to do a particular movement. It does not
/// include history or achievement information.
class Exercise: Hashable, Identifiable {
    var name: String             // "Heavy Bench"
    var formalName: String       // "Bench Press"
    var modality: Modality
    var expected: Expected
    var current: Current? = nil // this is reset to nil if it's been too long since the user was doing the exercise
    let id: Int

    init(_ name: String, _ formalName: String, _ modality: Modality, _ expected: Expected = Expected(weight: 0.0)) {
        self.name = name
        self.formalName = formalName
        self.modality = modality
        self.expected = expected
        self.id = nextID
        nextID += 1
    }
        
    static func ==(lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
