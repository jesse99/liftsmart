//  Created by Jesse Jones on 4/18/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

enum LogLevel {case Error; case Warning; case Info; case Debug}

struct LogLine {
    let seconds: TimeInterval   // since program started
    let level: LogLevel
    let line: String
}

var logLines: [LogLine] = []

func log(_ level: LogLevel, _ message: String) {
    while let line = logLines.first, line.seconds > 5*60 {
        logLines.remove(at: 0)
    }

    let elapsed = Date().timeIntervalSince1970 - startTime
    logLines.append(LogLine(seconds: elapsed, level: level, line: message))

#if targetEnvironment(simulator)
    let timestamp = String(format: "%.1f", elapsed)

    var prefix = ""
    switch level {
    case .Error:
        prefix = "ERR "
    case .Warning:
        prefix = "WARN"
    case .Info:
        prefix = "INFO"
    case .Debug:
        prefix = "DBG "
    }

    print("\(timestamp) \(prefix): \(message)")
#endif
}

// TODO: I think this isn't set until log() is called
fileprivate let startTime = Date().timeIntervalSince1970
