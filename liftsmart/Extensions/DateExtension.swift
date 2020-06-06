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
}
