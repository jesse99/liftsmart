//  Created by Jesse Jones on 2/21/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

/// List of arbitrary weights, e.g. for dumbbells or a cable machine.
class FixedWeightSet: CustomDebugStringConvertible, Sequence, Storable {
    init() {
        self.weights = []
    }
    
    init(_ weights: [Double]) {
        self.weights = weights
    }
    
    required init(from store: Store) {
        self.weights = store.getDblArray("weights")
    }
    
    func clone() -> FixedWeightSet {
        let store = Store()
        store.addObj("self", self)
        let result: FixedWeightSet = store.getObj("self")
        return result
    }
        
    func save(_ store: Store) {
        store.addDblArray("weights", self.weights)
    }
    
    // TODO: should have methods like findClosestBelow and findClosestAbove
    
    func add(_ weight: Double) {
        if let index = self.weights.firstIndex(where: {$0 >= weight}) {
            if self.weights[index] != weight {            // ValidateFixedWeightRange allows overlapping ranges so we need to test for dupes
                self.weights.insert(weight, at: index)
            }
        } else {
            self.weights.append(weight)
        }
    }
    
    func remove(at: Int) {
        self.weights.remove(at: at)
    }
    
    var count: Int {
        get {return self.weights.count}
    }
    
    // Weights are guaranteed to be sorted.
    subscript(index: Int) -> Double {
        get {
            return self.weights[index]
        }
    }
    
    func makeIterator() -> Array<Double>.Iterator {
        return self.weights.makeIterator()
    }

    var debugDescription: String {
        get {
            let limit = 4
            
            var result = ""
            for i in 0...Swift.min(weights.count, limit) {
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

    private var weights: [Double]
}
