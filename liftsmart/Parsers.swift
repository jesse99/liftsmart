//  Created by Jesse Jones on 1/31/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

// IntList = Int (Space Int)*
func parseIntList(_ text: String, label: String, zeroOK: Bool = false, emptyOK: Bool = false) -> Either<String, [Int]> {
    var values: [Int] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        if let value = scanner.scanInt() {
            if zeroOK && value < 0 {
                return .left("\(label.capitalized) cannot be negative")
            } else if !zeroOK && value <= 0 {
                return .left("\(label.capitalized) must be greater than zero")
            }
            values.append(value)
        } else {
            return .left("Expected space separated integers for \(label)")
        }
    }
    
    if !scanner.isAtEnd {
        return .left("Expected space separated integers for \(label)")
    }

    if values.isEmpty && !emptyOK {
        return .left("\(label.capitalized) needs at least one number")
    }
    
    return .right(values)
}

// Rep = Int
func parseRep(_ text: String, label: String) -> Either<String, Int> {
    let scanner = Scanner(string: text)
    
    let rep = scanner.scanInt()
    if rep == nil {
        return .left("Expected a number for \(label)")
    }
    if rep! <= 0 {
        return .left("\(label.capitalized) must be greater than zero")
    }

    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be just a number")
    }
    
    return .right(rep!)
}

// Rep = Int?
func parseOptionalRep(_ text: String, label: String) -> Either<String, Int?> {
    let scanner = Scanner(string: text)
    if scanner.isAtEnd {
        return .right(nil)
    }
    
    let rep = scanner.scanInt()
    if rep == nil {
        return .left("Expected a number for \(label)")
    }
    if rep! <= 0 {
        return .left("\(label.capitalized) must be greater than zero")
    }

    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be just a number")
    }
    
    return .right(rep!)
}

// RepList = Int (Space Int)*
func parseRepList(_ text: String, label: String, emptyOK: Bool = false) -> Either<String, [Int]> {
    var reps: [Int] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        if let rep = scanner.scanInt() {
            if rep <= 0 {
                return .left("\(label.capitalized) must be greater than zero")
            }
            reps.append(rep)
        } else {
            return .left("Expected space separated integers for \(label)")
        }
    }
    
    if !scanner.isAtEnd {
        return .left("Expected space separated integers for \(label)")
    }

    if reps.isEmpty && !emptyOK {
        return .left("\(label.capitalized) needs at least one rep")
    }
    
    return .right(reps)
}

// RepRanges = RepRange+ ('x' Int)?
// RepRange = Int ('-' Int)?
// Int = [0-9]+
func parseRepRanges(_ text: String, label: String) -> Either<String, [RepRange]> {
    func parseRepRange(_ scanner: Scanner) -> Either<String, RepRange> {
        let min = scanner.scanInt()
        if min == nil {
            return .left("Expected a number for \(label) followed by optional '-max'")
        }
        if min! <= 0 {
            return .left("\(label.capitalized) must be greater than zero")
        }
        
        if scanner.scanString("-") != nil {
            let max = scanner.scanInt()
            if max == nil {
                return .left("Expected a number for \(label) followed by optional '-max'")
            }
            if min! > max! {
                return .left("\(label.capitalized) min reps cannot be greater than max reps")
            }
            return .right(RepRange(min: min!, max: max!))
        }

        return .right(RepRange(min!))
    }
    
    var reps: [RepRange] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        switch parseRepRange(scanner) {
        case .right(let rep): reps.append(rep)
        case .left(let err): return .left(err)
        }
        
        if scanner.scanString("x") != nil {
            if let n = scanner.scanInt(), n > 0 {
                reps = reps.duplicate(x: n)
                break
            } else {
                return .left("x should be followed by the number of times to duplicate")
            }
        }
    }
    
    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be rep ranges followed by an optional xN to repeat")
    }

    if reps.isEmpty {
        return .left("\(label.capitalized) needs at least one rep")
    }
    
    return .right(reps)
}

// Reps = Int+ ('x' Int)?
func parseReps(_ text: String, label: String, emptyOK: Bool = false) -> Either<String, [Int]> {
    func parseRep(_ scanner: Scanner) -> Either<String, Int> {
        let rep = scanner.scanInt()
        if rep == nil {
            return .left("Expected a number for \(label)")
        }
        if rep! <= 0 {
            return .left("\(label.capitalized) must be greater than zero")
        }
        
        return .right(rep!)
    }
    
    let scanner = Scanner(string: text)
    if scanner.isAtEnd && emptyOK {
        return .right([])
    }
    
    var reps: [Int] = []
    while !scanner.isAtEnd {
        switch parseRep(scanner) {
        case .right(let rep): reps.append(rep)
        case .left(let err): return .left(err)
        }
        
        if scanner.scanString("x") != nil {
            if let n = scanner.scanInt(), n > 0 {
                reps = reps.duplicate(x: n)
                break
            } else {
                return .left("x should be followed by the number of times to duplicate")
            }
        }
    }
    
    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be numbers followed by an optional xN to repeat")
    }

    return .right(reps)
}

// Percents = Double+ ('x' Int)?
func parsePercents(_ text: String, label: String) -> Either<String, [WeightPercent]> {
    func parsePercent(_ scanner: Scanner) -> Either<String, WeightPercent> {
        let percent = scanner.scanDouble()
        if percent == nil {
            return .left("Expected a number for \(label)")
        }
        if percent! < 0 {
            return .left("\(label.capitalized) cannot be negative")
        }
        if percent! > 150 {
            return .left("\(label.capitalized) is too big")
        }
        
        return .right(WeightPercent(percent!/100.0))
    }
    
    var percents: [WeightPercent] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        switch parsePercent(scanner) {
        case .right(let percent): percents.append(percent)
        case .left(let err): return .left(err)
        }
        
        if scanner.scanString("x") != nil {
            if let n = scanner.scanInt(), n > 0 {
                percents = percents.duplicate(x: n)
                break
            } else {
                return .left("x should be followed by the number of times to duplicate")
            }
        }
    }
    
    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be numbers followed by an optional xN to repeat")
    }

    return .right(percents)
}

// Times = Time+ ('x' Int)?
// Time = Int ('s' | 'm' | 'h')?    if units are missing seconds are assumed
// Int = [0-9]+
func parseTimes(_ text: String, label: String, zeroOK: Bool = false) -> Either<String, [Int]> {
    func parseTime(_ scanner: Scanner) -> Either<String, Int> {
        let time = scanner.scanDouble()
        if time == nil {
            return .left("Expected a number for \(label) followed by optional s, m, or h")
        }
        
        var secs = time!
        if scanner.scanString("s") != nil {
            // nothing to do
        } else if scanner.scanString("m") != nil {
            secs *=  60.0
        } else if scanner.scanString("h") != nil {
            secs *=  60.0*60.0
        }

        if secs < 0.0 {
            return .left("\(label.capitalized) time cannot be negative")
        }
        if secs.isInfinite {
            return .left("\(label.capitalized) time must be finite")
        }
        if secs.isNaN {
            return .left("\(label.capitalized) time must be a number")
        }
        if !zeroOK && secs == 0.0 {
            return .left("\(label.capitalized) time cannot be zero")
        }

        return .right(Int(secs))
    }
    
    var times: [Int] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        switch parseTime(scanner) {
        case .right(let time): times.append(time)
        case .left(let err): return .left(err)
        }
        
        if scanner.scanString("x") != nil {
            if let n = scanner.scanInt(), n > 0 {
                times = times.duplicate(x: n)
                break
            } else {
                return .left("x should be followed by the number of times to duplicate")
            }
        }
    }
    
    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be times followed by an optional xN to repeat")
    }
    
    return .right(times)
}
