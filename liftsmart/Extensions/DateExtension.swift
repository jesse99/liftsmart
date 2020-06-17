//  Created by Jesse Jones on 6/6/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

extension Date {
    func hoursSinceDate(_ rhs: Date) -> Double {
        let secs = self.timeIntervalSince(rhs)
        let mins = secs/60.0
        let hours = mins/60.0
        return hours
    }

    func daysSinceDate(_ rhs: Date) -> Double {
        let secs = self.startOfDay().timeIntervalSince(rhs.startOfDay())
        let mins = secs/60.0
        let hours = mins/60.0
        let days = hours/24.0
        return days
    }
    
    func startOfDay() -> Date {
        let calendar = Calendar.current
        let result = calendar.startOfDay(for: self)
        return result
    }
    
    /// Returns a human readable string for number of days.
    func daysName() -> String {
        let calendar = Calendar.current
        
        // This is a bit awful but I can't figure out a good way to do this
        // 1) calendar.ordinalityOfUnit(.Day, inUnit: .Era, forDate: self)
        // is close but doesn't return "the decomposed value" and doesn't
        // always work.
        // 2) timeIntervalSinceDate can be made to work but uses elapsed
        // time so odd things happen around midnight.
        // 3) components:fromDate:toDate:options: seems to work similarly to
        // timeIntervalSinceDate.
        if calendar.isDate(self, inSameDayAs: Date()) {
            return "today"
        }
        
        if let candidate = (calendar as NSCalendar).date(byAdding: .day, value: -1, to: Date(), options: .searchBackwards) , calendar.isDate(self, inSameDayAs: candidate) {
            return "yesterday"
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
