//  Created by Jesse Vorisek on 5/10/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

//// TODO:
//// support paired dumbbells
//// support magnets on dumbbells
//// better support barbell: bumpers, and magnets
//// support barbell, machine, pairedPlates, and singlePlates
enum Apparatus {
    /// Typically these are unweighted but users can enter an arbitrary weight if they are using a plate,
    /// kettlebell, chains, milk jug, or whatever (this comes from Expected).
    case bodyWeight

    /// In general we want to treat single and paired dumbbells the same (users want to think about the 60 pound dumbbell
    /// not that they are actually lifting 120 pounds). But for stuff like acheivements we want to know how much they
    /// actually did lift.
    case dumbbells(weights: [Double], magnets: [Double], paired: Bool)
}

extension Apparatus {
    // There doesn't seem to be a good way to use failable initializers with associated enum values.
    // So, instead of doing the invariant checks at construction time we'll use this lame, error
    // prone, second check.
    public func validate() -> Bool {
        switch self {
        case .bodyWeight:
            return true
            
        case .dumbbells(weights: let weights, magnets: let magnets, paired: _):
            if weights.isEmpty {
                return false
            }
            if weights.any({$0 <= 0.0}) {
                return false
            }
            if magnets.any({$0 <= 0.0}) {
                return false
            }
        }
        
        return true
    }
}

extension Apparatus: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "bodyWeight":
            self = .bodyWeight
            
        case "dumbbells":
            let weights = store.getDblArray("weights")
            let magnets = store.getDblArray("magnets")
            let paired = store.getBool("paired")
            self = .dumbbells(weights: weights, magnets: magnets, paired: paired)
            
        default:
            assert(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .bodyWeight:
            store.addStr("type", "bodyWeight")
            
        case .dumbbells(weights: let weights, magnets: let magnets, paired: let paired):
            store.addStr("type", "dumbbells")
            store.addDblArray("weights", weights)
            store.addDblArray("magnets", magnets)
            store.addBool("paired", paired)
        }
    }
}
