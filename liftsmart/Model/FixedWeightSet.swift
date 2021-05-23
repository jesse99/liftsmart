//  Created by Jesse Jones on 2/21/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

class FixedWeights: CustomDebugStringConvertible, Sequence, Storable {
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
    
    func firstIndex(where predicate: (Double) -> Bool) -> Int? {
        return self.weights.firstIndex(where: predicate)
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

/// List of arbitrary weights, e.g. for dumbbells or a cable machine.
class FixedWeightSet: Storable {
    var weights: FixedWeights
    var extra: FixedWeights
    var extraAdds: Int          // number of extra weights that can be added to the maiun weight

    init() {
        self.weights = FixedWeights()
        self.extra = FixedWeights()
        self.extraAdds = 1
    }
    
    init(_ weights: [Double], extra: [Double] = [], extraAdds: Int = 1) {
        self.weights = FixedWeights(weights)
        self.extra = FixedWeights(extra)
        self.extraAdds = extraAdds
    }
    
    required init(from store: Store) {
        self.weights = store.getObj("weights2", ifMissing: FixedWeights())
        self.extra = store.getObj("extra", ifMissing: FixedWeights())
        self.extraAdds = store.getInt("extraAdds", ifMissing: 1)
    }
    
    func save(_ store: Store) {
        store.addObj("weights2", self.weights)
        store.addObj("extra", self.extra)
        store.addInt("extraAdds", self.extraAdds)
    }
    
    func clone() -> FixedWeightSet {
        let store = Store()
        store.addObj("self", self)
        let result: FixedWeightSet = store.getObj("self")
        return result
    }
        
    func getClosest(_ target: Double) -> Double {
        let below = self.getClosestBelow(target)
        let above = self.getClosestAbove(target)
        if above != nil {
            if abs(below - target) <= abs(above! - target) {
                return below
            } else {
                return above!
            }
        } else {
            return below
        }
    }
    
    func getClosestBelow(_ target: Double) -> Double {
        if let index = self.weights.firstIndex(where: {$0 > target}), index > 0 {
            return self.weights[index - 1]
        } else {
            return 0.0
        }
    }
    
    func getClosestAbove(_ target: Double) -> Double? {
        if let index = self.weights.firstIndex(where: {$0 >= target}) {
            return self.weights[index]
        } else {
            return nil
        }
    }
}
