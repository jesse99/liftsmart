//  Created by Jesse Vorisek on 5/10/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

fileprivate func joinSets(_ sets: [String]) -> String {
    if sets.count == 1 {
        return sets[0]

    } else if sets.all({$0 == sets[0]}) {      // init/validate should ensure that we always have at least one set
        return "\(sets.count)x\(sets[0])"

    } else {
        return sets.joined(separator: ", ")
    }
}

struct RepRange: CustomDebugStringConvertible, Storable {
    let min: Int
    let max: Int
    
    private init(_ min: Int, _ max: Int) {
        self.min = min
        self.max = max
    }
    
    static func create(_ min: Int) -> Either<String, RepRange> {
        if min <= 0 {return .left("Min rep cannot be negative")}
        return .right(RepRange(min, min))
    }
    
    static func create(min: Int, max: Int) -> Either<String, RepRange> {
        if min <= 0 {return .left("Min rep cannot be negative")}
        if min > max {return .left("Min rep cannot be larger than max rep")}
        return .right(RepRange(min, max))
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
        return RepRange.create(min: min!, max: max ?? min!)
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

    private init(_ value: Double) {
        self.value = value
    }
    
    static func create(_ value: Double) -> Either<String, WeightPercent> {
        // For a barbell 0% means just the bar.
        // For a dumbbell 0% means no weight which could be useful for warmups when very light weights are used.
        if value < 0.0 {return .left("Percent cannot be negative")}

        // Some programs, like CAP3, call for lifting a bit over 100% on some days. But we'll consider it an error if the user tries to lift way over 100%.
        if value > 1.5 {return .left("Percent is too big")}

        if value.isNaN {return .left("Percent isn't a valid number")}
        
        return .right(WeightPercent(value))
    }
    
    // INT
    static func create(_ text: String) -> Either<String, WeightPercent> {
        let scanner = Scanner(string: text)
        
        let p = scanner.scanDouble()
        if p == nil || !scanner.isAtEnd {
            return .left("Expected percent, e.g. 80")
        }
        return WeightPercent.create(p!/100.0)
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

// INT ('s' | 'm')?
func parseTime(_ text: String, _ label: String) -> Either<String, Int> {
    let scanner = Scanner(string: text)
    
    let secs = scanner.scanDouble()
    let units = scanner.scanCharacter()
    if secs == nil {
        return .left("Expected a number for \(label.lowercased())")
    }
    if let u = units, u != "s" && u != "m" {
        return .left("\(label) units should be 's' or 'm'")
    }
    if !scanner.isAtEnd {
        return .left("\(label) should be a number followed by optional s or m units")
    }
    let r = secs! * ((units ?? "s") == "s" ? 1.0 : 60.0)
    return .right(Int(r))
}

fileprivate func timeToStr(_ secs: Int) -> String {
    if secs <= 0 {
        return "0s"

    } else if secs <= 60 {
        return "\(secs)s"
    
    } else {
        let s = friendlyFloat(String.init(format: "%.1f", Double(secs)/60.0))
        return s + "m"
    }
}

struct Rest: CustomDebugStringConvertible { // for historical reasons this is not Storable
    let secs: Int
    
    private init(_ secs: Int) {
        self.secs = secs
    }
    
    static func create(secs: Int) -> Either<String, Rest> {
        if secs < 0 {return .left("Rest cannot be negative")}
        return .right(Rest(secs))
    }
        
    static func create(_ text: String) -> Either<String, Rest> {
        switch parseTime(text, "Rest") {
        case .right(let s):
            return Rest.create(secs: s)
        case .left(let e):
            return .left(e)
        }
    }

    var label: String {
        get {
            return timeToStr(secs)
        }
    }
    
    var editable: String {
        return self.label
    }
    
    var debugDescription: String {
        return self.label
    }
    
    // TODO: Do we stilll want phash?
    fileprivate func phash() -> Int {
        return self.secs.hashValue
    }
}

struct Duration: CustomDebugStringConvertible { // for historical reasons this is not Storable
    let secs: Int
    
    private init(_ secs: Int) {
        self.secs = secs
    }
    
    static func create(secs: Int) -> Either<String, Duration> {
        if secs <= 0 {return .left("Duration cannot be zero or negative")}
        return .right(Duration(secs))
    }
        
    static func create(_ text: String) -> Either<String, Duration> {
        switch parseTime(text, "Duration") {
        case .right(let s):
            return Duration.create(secs: s)
        case .left(let e):
            return .left(e)
        }
    }

    var label: String {
        get {
            return timeToStr(secs)
        }
    }
    
    var editable: String {
        return self.label
    }
    
    var debugDescription: String {
        return self.label
    }
    
    // TODO: Do we stilll want phash?
    fileprivate func phash() -> Int {
        return self.secs.hashValue
    }
}

struct RepsSet: CustomDebugStringConvertible, Storable {
    let reps: RepRange
    let percent: WeightPercent
    let rest: Rest
    
    private init(reps: RepRange, percent: WeightPercent, rest: Rest) {
        self.reps = reps
        self.percent = percent
        self.rest = rest
    }
    
    static func create(reps: RepRange, percent: WeightPercent = WeightPercent.create(1.0).unwrap(), rest: Rest = Rest.create(secs: 0).unwrap()) -> Either<String, RepsSet> {
        return .right(RepsSet(reps: reps, percent: percent, rest: rest))
    }
    
    init(from store: Store) {
        self.reps = store.getObj("reps")
        self.percent = store.getObj("percent")
        self.rest = Rest.create(secs: store.getInt("restSecs")).unwrap()
    }
    
    func save(_ store: Store) {
        store.addObj("reps", reps)
        store.addObj("percent", percent)
        store.addInt("restSecs", rest.secs)
    }

    var debugDescription: String {
        get {
            let display = self.percent.value >= 0.01 && self.percent.value <= 0.99
            let suffix = display ? " @ \(self.percent.label)" : ""

            return "\(self.reps.label)\(suffix)"
        }
    }
    
    fileprivate func phash() -> Int {
        return self.reps.phash() &+ self.percent.phash() &+ self.rest.phash()
    }
}

struct DurationSet: CustomDebugStringConvertible, Storable {
    let duration: Duration
    let rest: Rest
    
    private init(duration: Duration, rest: Rest) {
        self.duration = duration
        self.rest = rest
    }

    static func create(duration: Duration, rest: Rest = Rest.create(secs: 0).unwrap()) -> Either<String, DurationSet> {
        return .right(DurationSet(duration: duration, rest: rest))
    }

    init(from store: Store) {
        self.duration = Duration.create(secs: store.getInt("secs")).unwrap()
        self.rest = Rest.create(secs: store.getInt("restSecs")).unwrap()
    }
    
    func save(_ store: Store) {
        store.addInt("secs", duration.secs)
        store.addInt("restSecs", rest.secs)
    }

    var debugDescription: String {
        get {
            return duration.label
        }
    }
}

struct Durations: CustomDebugStringConvertible {
    let durations: [DurationSet]
    let target: [Duration]
    
    private init(_ durations: [DurationSet], target: [Duration]) {
        self.durations = durations
        self.target = target
    }

    static func create(_ durations: [DurationSet], target: [Duration] = []) -> Either<String, Durations> {
        if durations.isEmpty {return .left("Durations cannot be empty")}
        if target.count > 0 && target.count != durations.count {return .left("Target must be either empty or have the same count as durations")}

        return .right(Durations(durations, target: target))
    }

    init(from store: Store) {
        self.durations = store.getObjArray("durations")
        let tarAry = store.getIntArray("targetSecs")
        self.target = tarAry.map({Duration.create(secs: $0).unwrap()})
    }
    
    func save(_ store: Store) {
        store.addObjArray("durations", durations)
        let tar = target.map({$0.secs})
        store.addIntArray("targetSecs", tar)
    }

    var debugDescription: String {
        get {
            return joinSets(self.durations.map({$0.debugDescription}))
        }
    }
}

// TODO: to make this safe would have to have structs like Durations, MaxReps, etc
// See https://forums.swift.org/t/access-control-for-enum-case-initializers/22663
// make sure load from store still works
enum Sets: CustomDebugStringConvertible {
    /// Used for stuff like 3x60s planks.
    case durations(Durations)

    /// Used for stuff like curls to exhaustion. targetReps is the reps across all sets.
    case maxReps(rest: [Rest], targetReps: Int? = nil)
    
    /// Used for stuff like 3x5 squat or 3x8-12 lat pulldown.
    case repRanges(warmups: [RepsSet], worksets: [RepsSet], backoffs: [RepsSet])

//    case untimed(rest: [Rest])
    
    // TODO: Will need some sort of rep target case (for stuff like pullups).

    var debugDescription: String {
        get {
            var sets: [String] = []
            
            switch self {
            case .durations(let durations):
                return durations.debugDescription

            case .maxReps(let restSecs, _):
                sets = ["\(restSecs.count) sets"]

            case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
                sets = worksets.map({$0.debugDescription})

//            case .untimed(restSecs: let secs):
//                sets = Array(repeating: "untimed", count: secs.count)
            }
            
            return joinSets(sets)   // TODO: lose this
        }
    }
}

extension Sets {
    func validate() -> Bool {
        switch self {
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
                
        case .maxReps(rest: let rest, targetReps: let targetReps):
            if rest.isEmpty {return false}
            if let target = targetReps {
                if target <= 0 {return false}
            }

//        case .untimed(restSecs: let secs):
//            if secs.isEmpty {return false}
//            if secs.any({$0 < 0}) {return false}
        
        default:
            break
        }
        
       return true
    }
}

extension Sets: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "durations":
            self = .durations(Durations(from: store))
            
        case "maxReps":
            let restAry = store.getIntArray("restSecs")
            let rest = restAry.map({Rest.create(secs: $0).unwrap()})
            if store.hasKey("targetReps") {
                self = .maxReps(rest: rest, targetReps: store.getInt("targetReps"))
            } else {
                self = .maxReps(rest: rest, targetReps: nil)
            }
            
        case "repRanges":
            self = .repRanges(warmups: store.getObjArray("warmups"), worksets: store.getObjArray("worksets"), backoffs: store.getObjArray("backoffs"))
            
        default:
            assert(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .durations(let durations):
            store.addStr("type", "durations")
            durations.save(store)

        case .maxReps(let rest, let targetReps):
            store.addStr("type", "maxReps")
            let r = rest.map({$0.secs})
            store.addIntArray("restSecs", r)
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
