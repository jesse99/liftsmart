//  Created by Jesse Jones on 5/31/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

func secsToShortDurationName(_ interval: Double) -> String {
    let secs = Int(round(interval))
    let mins = interval/60.0
    let hours = interval/3600.0
    let days = round(hours/24.0)
    
    if secs < 120 {
        return secs == 1 ? "1 sec" : "\(secs) secs"
    } else if mins < 60.0 {
        return String(format: "%0.1f mins", arguments: [mins])
    } else if hours < 24.0 {
        return String(format: "%0.1f hours", arguments: [hours])
    } else {
        return String(format: "%0.1f days", arguments: [days])
    }
}

extension Date {
    /// Returns a human readable string for number of days.
    func friendlyName() -> String {
        // today always makes sense.
        let calendar = Calendar.current
        if calendar.isDate(self, inSameDayAs: Date()) {
            return "today"
        }

        // yesterday gets a little funny for people working out through midnight so we'll report hours
        // if the date is technically yesterday but not too long ago. Note that we want to keep the
        // reported interval fairly coarse so that we can run timers on a long interval (and avoid chewing
        // up battery life).
        let hours = Date().hoursSinceDate(self).rounded()
        if let candidate = (calendar as NSCalendar).date(byAdding: .day, value: -1, to: Date(), options: .searchBackwards) , calendar.isDate(self, inSameDayAs: candidate) {
            if hours > 4.0 {
                return "yesterday"
            } else {
                if hours < 1.0 {
                    return "under an hour ago"
                }
                if hours < 2.0 {
                    return "about an hour ago"
                }
                if hours < 24.0 {
                    return String(format: "%0.0f hours ago", arguments: [hours])
                }
            }
        }
        
        for days in 2...31 {
            if let candidate = (calendar as NSCalendar).date(byAdding: .day, value: -days, to: Date(), options: .searchBackwards) , calendar.isDate(self, inSameDayAs: candidate) {
                return "\(days) days ago"
            }
        }
        
        for months in 1...12 {
            if let candidate = (calendar as NSCalendar).date(byAdding: .month, value: -months, to: Date(), options: .searchBackwards) , (calendar as NSCalendar).isDate(self, equalTo: candidate, toUnitGranularity: .month) {
                if months == 1 {
                    return "1 month ago"
                } else {
                    return "\(months) months ago"
                }
            }
        }
        
        for years in 1...10 {
            if let candidate = (calendar as NSCalendar).date(byAdding: .year, value: -years, to: Date(), options: .searchBackwards) , (calendar as NSCalendar).isDate(self, equalTo: candidate, toUnitGranularity: .year) {
                if years == 1 {
                    return "1 year ago"
                } else {
                    return "\(years) years ago"
                }
            }
        }
        
        return ">10 years ago"
    }
}

func friendlyFloat(_ str: String) -> String {
    var result = str
    while result.hasSuffix("0") {
        let start = result.index(result.endIndex, offsetBy: -1)
        let end = result.endIndex
        result.removeSubrange(start..<end)
    }
    if result.hasSuffix(".") {
        let start = result.index(result.endIndex, offsetBy: -1)
        let end = result.endIndex
        result.removeSubrange(start..<end)
    }
    
    return result
}

func friendlyWeight(_ weight: Double) -> String {
    var result: String
    
    // Note that weights are always stored as lbs internally.
    //        let app = UIApplication.shared.delegate as! AppDelegate
    //        switch app.units()
    //        {
    //        case .imperial:
    //            // Kind of annoying to use three decimal places but people
    //            // sometimes use 0.625 fractional plates (5/8 lb).
    result = String(format: "%.3f", weight)
    //
    //        case .metric:
    //            result = String(format: "%.2f", arguments: [weight*Double.lbToKg])
    //        }
    
    return friendlyFloat(result)
}

func friendlyUnitsWeight(_ weight: Double, plural: Bool = true) -> String {
    if plural {
        return friendlyWeight(weight) + " lbs"  // TODO: also kg
    } else {
        return friendlyWeight(weight) + " lb"
    }
}

/// Replaces consecutive duplicate strings, e.g. ["alpha", "alpha", "beta"]
/// becomes ["2xalpha", "beta"].
func dedupe(_ sets: [String]) -> [String] {
    func numDupes(_ i: Int) -> Int {
        var count = 1
        while i+count < sets.count && sets[i] == sets[i+count] {
            count += 1
        }
        return count
    }
                
    var i = 0
    var result: [String] = []
    while i < sets.count {
        let count = numDupes(i)
        if count > 1 {
            result.append("\(count)x\(sets[i])")
            i += count
            
        } else {
            result.append(sets[i])
            i += 1
        }
    }
    
    return result
}

