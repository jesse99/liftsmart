//  Created by Jesse Jones on 7/3/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

// From https://forums.swift.org/t/make-implicit-units-on-timeinterval-explicit/11383
extension TimeInterval {
    internal static var secondsPerDay: Double { return 24 * 60 * 60 }
    internal static var secondsPerHour: Double { return 60 * 60 }
    internal static var secondsPerMinute: Double { return 60 }
    internal static var millisecondsPerSecond: Double { return 1_000 }
    internal static var microsecondsPerSecond: Double { return 1_000 * 1_000 }
    internal static var nanosecondsPerSecond: Double { return 1_000 * 1_000 * 1_000 }

    /// - Returns: The time in days using the `TimeInterval` type.
    public static func days(_ value: Double) -> TimeInterval {
        return value * secondsPerDay
    }

    /// - Returns: The time in hours using the `TimeInterval` type.
    public static func hours(_ value: Double) -> TimeInterval {
        return value * secondsPerHour
    }

    /// - Returns: The time in minutes using the `TimeInterval` type.
    public static func minutes(_ value: Double) -> TimeInterval {
        return value * secondsPerMinute
    }

    /// - Returns: The time in seconds using the `TimeInterval` type.
    public static func seconds(_ value: Double) -> TimeInterval {
        return value
    }

    /// - Returns: The time in milliseconds using the `TimeInterval` type.
    public static func milliseconds(_ value: Double) -> TimeInterval {
        return value / millisecondsPerSecond
    }

    /// - Returns: The time in microseconds using the `TimeInterval` type.
    public static func microseconds(_ value: Double) -> TimeInterval {
        return value / microsecondsPerSecond
    }

    /// - Returns: The time in nanoseconds using the `TimeInterval` type.
    public static func nanoseconds(_ value: Double) -> TimeInterval {
        return value / nanosecondsPerSecond
    }
}
