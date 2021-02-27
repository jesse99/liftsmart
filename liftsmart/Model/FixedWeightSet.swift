//  Created by Jesse Jones on 2/21/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

/// List of arbitrary weights, e.g. for dumbbells or a cable machine.
class FixedWeightSet: CustomDebugStringConvertible, Storable {
    var weights: [Double]
    
    init(_ weights: [Double]) {
        self.weights = weights
    }
    
    required init(from store: Store) {
        self.weights = store.getDblArray("weights")
    }
    
    func save(_ store: Store) {
        store.addDblArray("weights", self.weights)
    }

    var debugDescription: String {
        get {
            let limit = 4
            
            var result = ""
            for i in 0...min(weights.count, limit) {
                if !result.isEmpty {
                    result += ", "
                }
                result += friendlyWeight(weights[i])
            }
            if weights.count > limit {
                result += ", ..."
            }
            
            return result
        }
    }
}

var fixedWeights: [String: FixedWeightSet] = [:]
