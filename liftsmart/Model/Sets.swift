//  Created by Jesse Vorisek on 5/10/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

struct RepRange: CustomDebugStringConvertible, Storable {
    let min: Int
    let max: Int
    
    init?(_ reps: Int) {
        if reps <= 0 {return nil}
        
        self.min = reps
        self.max = reps
    }
    
    init?(min: Int, max: Int) {
        if min <= 0 {return nil}
        if min > max {return nil}

        self.min = min
        self.max = max
    }

    var label: String {
        get {
            if min < max {
                return "\(min)-\(max) reps"
            } else {
                if min == 1 {
                    return "1 rep"
                } else {
                    return "\(min) reps"
                }
            }
        }
    }
    
    init(from store: Store) {
        self.min = store.getInt("min")
        self.max = store.getInt("max")
    }
    
    func save(_ store: Store) {
        store.addInt("min", min)
        store.addInt("max", max)
    }

    var debugDescription: String {
        return self.label
    }
    
    // TODO: Do we stilll want phash?
    fileprivate func phash() -> Int {
        return self.min.hashValue &+ self.max.hashValue
    }
}

struct WeightPercent: CustomDebugStringConvertible, Storable {
    let value: Double

    init?(_ value: Double) {
        // For a barbell 0% means just the bar.
        // For a dumbbell 0% means no weight which could be useful for warmups when very light weights are used.
        if value < 0.0 {return nil}

        // Some programs, like CAP3, call for lifting a bit over 100% on some days. But we'll consider it an error if the user tries to lift way over 100%.
        if value > 1.5 {return nil}

        if value.isNaN {return nil}
        
        self.value = value
    }
    
    static func * (lhs: Double, rhs: WeightPercent) -> Double {
        return lhs * rhs.value
    }

    var label: String {
        get {
            let i = Int(self.value*100)
            if abs(self.value - Double(i)) < 1.0 {
                return ""
            } else {
                return "\(i)%"
            }
        }
    }
    
    init(from store: Store) {
        self.value = store.getDbl("value")
    }
    
    func save(_ store: Store) {
        store.addDbl("value", value)
    }

    var debugDescription: String {
        get {
            return String(format: "%.1f%%", 100.0*self.value)
        }
    }
    
    fileprivate func phash() -> Int {
        return self.value.hashValue
    }
}

struct RepsSet: CustomDebugStringConvertible, Storable {
    let reps: RepRange
    let percent: WeightPercent
    let restSecs: Int
    
    init?(reps: RepRange, percent: WeightPercent = WeightPercent(1.0)!, restSecs: Int = 0) {
        if restSecs < 0 {return nil}
        
        self.reps = reps
        self.percent = percent
        self.restSecs = restSecs
    }
    
    init(from store: Store) {
        self.reps = store.getObj("reps")
        self.percent = store.getObj("percent")
        self.restSecs = store.getInt("restSecs")
    }
    
    func save(_ store: Store) {
        store.addObj("reps", reps)
        store.addObj("percent", percent)
        store.addInt("restSecs", restSecs)
    }

    var debugDescription: String {
        get {
            return "\(self.reps.label)\(self.percent.label)"
        }
    }
    
    fileprivate func phash() -> Int {
        return self.reps.phash() &+ self.percent.phash() &+ self.restSecs.hashValue
    }
}

struct DurationSet: CustomDebugStringConvertible, Storable {
    let secs: Int
    let restSecs: Int
    
    init?(secs: Int, restSecs: Int = 0) {
        if secs <= 0 {return nil}
        if restSecs < 0 {return nil}

        self.secs = secs
        self.restSecs = restSecs
    }

    init(from store: Store) {
        self.secs = store.getInt("secs")
        self.restSecs = store.getInt("restSecs")
    }
    
    func save(_ store: Store) {
        store.addInt("secs", secs)
        store.addInt("restSecs", restSecs)
    }

    var debugDescription: String {
        get {
            return "\(self.secs)s"
        }
    }
}

enum Sets: CustomDebugStringConvertible {
    /// Used for stuff like 3x60s planks.
    case durations([DurationSet], targetSecs: [Int] = [])

    /// Used for stuff like curls to exhaustion. targetReps is the reps across all sets.
    case maxReps(restSecs: [Int], targetReps: Int? = nil)
    
    /// Used for stuff like 3x5 squat or 3x8-12 lat pulldown.
    case repRanges(warmups: [RepsSet], worksets: [RepsSet], backoffs: [RepsSet])

//    case untimed(restSecs: [Int])
    
    // TODO: Will need some sort of reps target case (for stuff like pullups).

    var debugDescription: String {
        get {
            var sets: [String] = []
            
            switch self {
            case .durations(let durations, _):
                sets = durations.map({$0.debugDescription})

            case .maxReps(let restSecs, _):
                sets = ["\(restSecs.count) sets"]

            case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
                sets = worksets.map({$0.debugDescription})

//            case .untimed(restSecs: let secs):
//                sets = Array(repeating: "untimed", count: secs.count)
            }
            
            if sets.count == 1 {
                return sets[0]

            } else if sets.all({$0 == sets[0]}) {      // init/validate should ensure that we always have at least one set
                return "\(sets.count)x\(sets[0])"

            } else {
                return sets.joined(separator: ", ")
            }
        }
    }
}

extension Sets {
    func validate() -> Bool {
        switch self {
        case .durations(let durations, targetSecs: let targetSecs):
            if durations.isEmpty {return false}
            if targetSecs.count > 0 && targetSecs.count != durations.count {return false}
            for target in targetSecs {
                if target <= 0 {return false}
            }

        case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
            if worksets.isEmpty {return false}
            
            // Note that RepRange init takes care of checking min > max.
            var minReps: Int? = nil
            var maxReps: Int? = nil
            for set in worksets {
                if set.reps.min < set.reps.max {
                    if minReps == nil {
                        minReps = set.reps.min
                        maxReps = set.reps.max
                    } else {
                        if minReps! != set.reps.min || maxReps! != set.reps.max {
                            // Disallow worksets like [4-8, 3-5] so that we can always return something sensible from repRange.
                            return false
                        }
                    }
                }
            }
                
        case .maxReps(restSecs: let secs, targetReps: let targetReps):
            if secs.isEmpty {return false}
            for sec in secs {
                if sec <= 0 {return false}
            }
            if let target = targetReps {
                if target <= 0 {return false}
            }

//        case .untimed(restSecs: let secs):
//            if secs.isEmpty {return false}
//            if secs.any({$0 < 0}) {return false}
        }
        
       return true
    }
}

extension Sets: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "durations":
            self = .durations(store.getObjArray("durations"), targetSecs: store.getIntArray("targetSecs"))
            
        case "maxReps":
            if store.hasKey("targetReps") {
                self = .maxReps(restSecs: store.getIntArray("restSecs"), targetReps: store.getInt("targetReps"))
            } else {
                self = .maxReps(restSecs: store.getIntArray("restSecs"), targetReps: nil)
            }
            
        case "repRanges":
            self = .repRanges(warmups: store.getObjArray("warmups"), worksets: store.getObjArray("worksets"), backoffs: store.getObjArray("backoffs"))
            
        default:
            assert(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .durations(let durations, let targetSecs):
            store.addStr("type", "durations")
            store.addObjArray("durations", durations)
            store.addIntArray("targetSecs", targetSecs)

        case .maxReps(let restSecs, let targetReps):
            store.addStr("type", "maxReps")
            store.addIntArray("restSecs", restSecs)
            if let target = targetReps {
                store.addInt("targetReps", target)
            }

        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            store.addStr("type", "repRanges")
            store.addObjArray("warmups", warmups)
            store.addObjArray("worksets", worksets)
            store.addObjArray("backoffs", backoffs)
        }
    }
}
