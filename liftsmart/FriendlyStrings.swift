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

func friendlyUnitsWeight(_ weight: Double, plural: Bool = true) -> String {
    if plural {
        return friendlyWeight(weight) + " lbs"  // TODO: also kg
    } else {
        return friendlyWeight(weight) + " lb"
    }
}
