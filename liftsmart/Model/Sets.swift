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

struct RepRange: CustomDebugStringConvertible, Storable {
    let min: Int
    let max: Int
    
    init(_ reps: Int) {
        self.min = reps
        self.max = reps
    }
    
    init(min: Int, max: Int) {
        self.min = min
        self.max = max
    }
    
    // INT(-INT)?
    static func create(_ text: String) -> Either<String, RepRange> {
        let scanner = Scanner(string: text)
        
        let min = scanner.scanInt()
        let sep = scanner.scanString("-")
        let max = scanner.scanInt()
        if (min == nil) || (sep != nil && max == nil) || !scanner.isAtEnd {
            return .left("Expected a rep or rep range, e.g. 4 or 4-8")
        }
        if min! < 0 {
            return .left("Reps cannot be negative")
        }
        if sep == nil && max == nil {
            return .right(RepRange(min!))
        }
        if min! > max! {
            return .left("Min reps must be smaller than max reps")
        }
        return .right(RepRange(min: min!, max: max!))
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
    
    var editable: String {
        get {
            if min < max {
                return "\(min)-\(max)"
            } else {
                return "\(min)"
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

    init(_ value: Double) {
        self.value = value
    }
    
    // INT
    static func create(_ text: String) -> Either<String, WeightPercent> {
        let scanner = Scanner(string: text)
        
        let p = scanner.scanDouble()
        if p == nil || !scanner.isAtEnd {
            return .left("Expected percent, e.g. 80")
        }
        if p! < 0 {
            return .left("Percent cannot be negative")
        }
        if p! > 150 {
            return .left("Percent is too big")
        }
        return .right(WeightPercent(p!/100.0))
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

struct RepsSet: CustomDebugStringConvertible, Storable {
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
    
    func titles(_ expected: Expected, _ reps: RepRange) -> (String, String) {
        let weight = expected.weight * percent
        let display = percent.value >= 0.01 && percent.value <= 0.99
        let percentTitle = display ? "\(percent.label) of \(expected.weight) lbs" : ""

        let suffix = percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
        let repsTitle = reps.label + suffix
        
        return (percentTitle, repsTitle)
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

struct DurationSet: CustomDebugStringConvertible, Storable {
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

enum Sets: CustomDebugStringConvertible {
    /// Used for stuff like 3x60s planks.
    case durations([DurationSet], targetSecs: [Int] = [])
    
    /// Does not allow variable reps, useful for things like stretches.
    case fixedReps([RepsSet])

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

            case .fixedReps(let worksets):
                sets = worksets.map({$0.debugDescription})

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
        }
    }
}
