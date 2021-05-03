//  Created by Jesse Vorisek on 5/10/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

func restToStr(_ secs: Int) -> String {
    if secs <= 0 {
        return "0s"

    } else if secs <= 60 {
        return "\(secs)s"
    
    } else {
        let s = friendlyFloat(String.init(format: "%.1f", Double(secs)/60.0))
        return s + "m"
    }
}

func weightSuffix(_ percent: WeightPercent, _ maxWeight: Double) -> String {
    let weight = maxWeight * percent
    return percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
}

struct FixedReps: CustomDebugStringConvertible, Equatable, Storable {
    let reps: Int
    
    init(_ reps: Int) {
        self.reps = reps
    }
    
    var label: String {
        get {
            return "\(reps) reps"
        }
    }
    
    var editable: String {
        get {
            return "\(reps)"
        }
    }
    
    init(from store: Store) {
        self.reps = store.getInt("min") // min for historical reasons
    }
    
    func save(_ store: Store) {
        store.addInt("min", reps)
    }

    var debugDescription: String {
        return self.label
    }
    
    fileprivate func phash() -> Int {
        return self.reps.hashValue
    }
}

struct RepRange: CustomDebugStringConvertible, Equatable, Storable {
    let min: Int
    let max: Int?   // missing means min+
    
    init(min: Int, max: Int?) {
        self.min = min
        self.max = max
    }
    
    var label: String {
        get {
            if let max = self.max {
                if min < max {
                    return "\(min)-\(max) reps"
                } else {
                    if min == 1 {
                        return "1 rep"
                    } else {
                        return "\(min) reps"
                    }
                }
            } else {
                return "\(min)+ reps"
            }
        }
    }
    
    var editable: String {
        get {
            if let max = self.max {
                if min < max {
                    return "\(min)-\(max)"
                } else {
                    return "\(min)"
                }
            } else {
                return "\(min)+"
            }
        }
    }
    
    init(from store: Store) {
        self.min = store.getInt("min")
        if store.hasKey("max") {
            self.max = store.getInt("max")
        } else {
            self.max = nil
        }
    }
    
    func save(_ store: Store) {
        store.addInt("min", min)
        if let max = self.max {
            store.addInt("max", max)
        }
    }

    var debugDescription: String {
        return self.label
    }
    
    // TODO: Do we stilll want phash?
    fileprivate func phash() -> Int {
        return self.min.hashValue &+ self.max.hashValue
    }
}

struct WeightPercent: CustomDebugStringConvertible, Equatable, Storable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    static func * (lhs: Double, rhs: WeightPercent) -> Double {
        return lhs * rhs.value
    }

    var editable: String {
        get {
            let i = Int(self.value*100)
            if abs(self.value - Double(i)) < 1.0 {
                return "0"
            } else {
                return "\(i)"
            }
        }
    }
    
    var label: String {
        get {
            let e = self.editable;
            return e == "0" ? "" : e+"%";
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

struct FixedRepsSet: CustomDebugStringConvertible, Equatable, Storable {
    let reps: FixedReps
    let restSecs: Int
    
    init(reps: FixedReps, restSecs: Int = 0) {
        self.reps = reps
        self.restSecs = restSecs
    }
    
    init(from store: Store) {
        self.reps = store.getObj("reps")
        self.restSecs = store.getInt("restSecs")
    }
    
    func save(_ store: Store) {
        store.addObj("reps", reps)
        store.addInt("restSecs", restSecs)
    }
    
    var debugDescription: String {
        get {
            return "\(self.reps.label)"
        }
    }
    
    fileprivate func phash() -> Int {
        return self.reps.phash() &+ self.restSecs.hashValue
    }
}

struct RepsSet: CustomDebugStringConvertible, Equatable, Storable {
    let reps: RepRange
    let percent: WeightPercent
    let restSecs: Int
    
    init(reps: RepRange, percent: WeightPercent = WeightPercent(1.0), restSecs: Int = 0) {
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
            let display = self.percent.value >= 0.01 && self.percent.value <= 0.99
            let suffix = display ? " @ \(self.percent.label)" : ""

            return "\(self.reps.label)\(suffix)"
        }
    }
    
    fileprivate func phash() -> Int {
        return self.reps.phash() &+ self.percent.phash() &+ self.restSecs.hashValue
    }
}

struct DurationSet: CustomDebugStringConvertible, Equatable, Storable {
    let secs: Int
    let restSecs: Int
    
    init(secs: Int, restSecs: Int = 0) {
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

enum Sets: CustomDebugStringConvertible, Equatable {
    /// Used for stuff like 3x60s planks.
    case durations([DurationSet], targetSecs: [Int] = [])
    
    /// Does not allow variable reps or percents, useful for things like stretches.
    case fixedReps([FixedRepsSet])

    /// Used for stuff like curls to exhaustion. targetReps is the reps across all sets.
    case maxReps(restSecs: [Int], targetReps: Int? = nil)
    
    /// Used for stuff like 3x5 squat or 3x8-12 lat pulldown.
    case repRanges(warmups: [RepsSet], worksets: [RepsSet], backoffs: [RepsSet])
    
    /// Do target reps spread across as many sets as neccesary.
    case repTarget(target: Int, rest: Int)

//    case untimed(restSecs: [Int])
    
    // TODO: Will need some sort of reps target case (for stuff like pullups).

    var debugDescription: String {
        get {
            var sets: [String] = []
            
            switch self {
            case .durations(let durations, _):
                sets = durations.map({$0.debugDescription})

            case .fixedReps(let worksets):
                sets = worksets.map({$0.debugDescription})

            case .maxReps(let restSecs, _):
                sets = ["\(restSecs.count) sets"]

            case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
                sets = worksets.map({$0.debugDescription})

            case .repTarget(target: let target, rest: _):
                sets = ["\(target) reps"]

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

extension Sets: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "durations":
            self = .durations(store.getObjArray("durations"), targetSecs: store.getIntArray("targetSecs"))
            
        case "fixedReps":
            self = .fixedReps(store.getObjArray("worksets"))
            
        case "maxReps":
            if store.hasKey("targetReps") {
                self = .maxReps(restSecs: store.getIntArray("restSecs"), targetReps: store.getInt("targetReps"))
            } else {
                self = .maxReps(restSecs: store.getIntArray("restSecs"), targetReps: nil)
            }
            
        case "repRanges":
            self = .repRanges(warmups: store.getObjArray("warmups"), worksets: store.getObjArray("worksets"), backoffs: store.getObjArray("backoffs"))

        case "repTarget":
            self = .repTarget(target: store.getInt("target"), rest: store.getInt("rest"))
            
        default:
            ASSERT(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .durations(let durations, let targetSecs):
            store.addStr("type", "durations")
            store.addObjArray("durations", durations)
            store.addIntArray("targetSecs", targetSecs)

        case .fixedReps(let worksets):
            store.addStr("type", "fixedReps")
            store.addObjArray("worksets", worksets)

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

        case .repTarget(target: let target, rest: let rest):
            store.addStr("type", "repTarget")
            store.addInt("target", target)
            store.addInt("rest", rest)
        }
    }

    func numSets() -> Int? {
        switch self {
        case .durations(let durations, _):
            return durations.count

        case .fixedReps(let worksets):
            return worksets.count

        case .maxReps(let restSecs, _):
            return restSecs.count

        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            return warmups.count + worksets.count + backoffs.count

        case .repTarget(target: _, rest: _):
            return nil
        }
    }
    
    func sameCase(_ rhs: Sets) -> Bool {
        func token(_ sets: Sets) -> Int {
            switch sets {
            case .durations(_, targetSecs: _):
                return 0
            case .fixedReps(_):
                return 1
            case .maxReps(restSecs: _, targetReps: _):
                return 2
            case .repRanges(warmups: _, worksets: _, backoffs: _):
                return 3
            case .repTarget(target: _, rest: _):
                return 4
            }
        }
        
        return token(self) == token(rhs)
    }
}
