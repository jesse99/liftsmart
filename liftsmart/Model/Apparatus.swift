//  Created by Jesse Vorisek on 5/10/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

// TODO:
// support magnets/extra on fixedWeights
// support pairedPlates and singlePlates
// support bumpers, may want to use a PlateWeightSet here, plates have a weight/count
// support magnets
enum Apparatus: Equatable {
    /// Typically these are unweighted but users can enter an arbitrary weight if they are using a plate,
    /// kettlebell, chains, milk jug, or whatever (this comes from Expected).
    case bodyWeight

    /// This is used for dumbbels, kettlebells, cable machines, etc. Name references a FixedWeights object.
    /// If name is nil then the user hasn't activated a FixedWeight set yet.
    case fixedWeights(name: String?)
}

extension Apparatus: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "bodyWeight":
            self = .bodyWeight
            
        case "fixedWeights":
            let name = store.hasKey("name") ? store.getStr("name") : nil
            self = .fixedWeights(name: name)
            
        // This one is obsolete.
        case "dumbbells":
            self = .fixedWeights(name: nil)

        default:
            ASSERT(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .bodyWeight:
            store.addStr("type", "bodyWeight")
            
        case .fixedWeights(name: let name):
            store.addStr("type", "fixedWeights")
            if let name = name {
                store.addStr("name", name)
            }
        }
    }

    func sameCase(_ rhs: Apparatus) -> Bool {
        func token(_ apparatus: Apparatus) -> Int {
            switch apparatus {
            case .bodyWeight:
                return 0
            case .fixedWeights(name: _):
                return 1
            }
        }
        
        return token(self) == token(rhs)
    }
}
