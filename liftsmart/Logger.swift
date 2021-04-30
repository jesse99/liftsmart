//  Created by Jesse Jones on 4/18/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation
import SwiftUI

enum LogLevel: Int {case Error; case Warning; case Info; case Debug}

struct LogLine: Storable {
    let seconds: TimeInterval   // since program started
    let level: LogLevel
    let line: String
    let current: Bool           // true if the log line is for this run of the app
    
    init(_ seconds: TimeInterval, _ level: LogLevel, _ line: String, current: Bool = true) {
        self.seconds = seconds
        self.level = level
        self.line = line
        self.current = current
    }
    
    init(from store: Store) {
        self.seconds = store.getDbl("seconds")
        self.level = LogLevel(rawValue: store.getInt("level")) ?? .Info
        self.line = store.getStr("line")
        self.current = false
    }
    
    func save(_ store: Store) {
        store.addDbl("seconds", seconds)
        store.addInt("level", level.rawValue)
        store.addStr("line", line)
    }
}

var logLines: [LogLine] = []    // newest are at end
var numLogErrors = 0
var numLogWarnings = 0

func log(_ level: LogLevel, _ message: String) {
    while let line = logLines.first, line.seconds > 10*60 {
        if line.level == .Error {
            numLogErrors -= 1
        } else if line.level == .Warning {
            numLogWarnings -= 1
        }
        logLines.remove(at: 0)
    }

    let elapsed = Date().timeIntervalSince1970 - startTime
    let entry = LogLine(elapsed, level, message)
    logLines.append(entry)
    
    if entry.level == .Error {
        numLogErrors += 1
    } else if entry.level == .Warning {
        numLogWarnings += 1
    }

#if targetEnvironment(simulator)
let timestamp = entry.timeStr()
let prefix = entry.levelStr()
print("\(timestamp) \(prefix) \(message)")
#endif
}

extension LogLine {
    func timeStr() -> String {
        var elapsed = self.seconds
        if elapsed > 60*60 {
            let hours = floor(elapsed/(60*60))
            elapsed -= hours*60*60
            
            let mins = floor(elapsed/60)
            elapsed -= mins*60
            return String(format: "%.0f:%.0f:%.1f", hours, mins, elapsed)
        } else if elapsed > 60 {
            let mins = floor(elapsed/60)
            elapsed -= mins*60
            return String(format: "%.0f:%.1f", mins, elapsed)
        } else {
            return String(format: "%.1f", elapsed)
        }
    }

    func levelStr() -> String {
        switch self.level {
        case .Error:
            return "ERR "
        case .Warning:
            return "WARN"
        case .Info:
            return "INFO"
        case .Debug:
            return "DBG "
        }
    }
}

func saveLogs() {
    let store = Store()

    let app = UIApplication.shared.delegate as! AppDelegate
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    do {
        store.addObjArray("lines", logLines)
        store.addInt("numLogErrors", numLogErrors)
        store.addInt("numLogWarnings", numLogWarnings)

        let data = try encoder.encode(store)
        app.saveEncoded(data as AnyObject, to: "logs")
    } catch {
        log(.Error, "Failed to save logs: \(error.localizedDescription)")
    }
}

func clearLogs() {
    let store = Store()

    let app = UIApplication.shared.delegate as! AppDelegate
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    do {
        let lines: [LogLine] = []
        store.addObjArray("lines", lines)
        store.addInt("numLogErrors", 0)
        store.addInt("numLogWarnings", 0)

        let data = try encoder.encode(store)
        app.saveEncoded(data as AnyObject, to: "logs")
    } catch {
        log(.Error, "Failed to save logs: \(error.localizedDescription)")
    }
}

func loadLogs() {
    let app = UIApplication.shared.delegate as! AppDelegate
    if let store = app.loadStore(from: "logs") {
        logLines = store.getObjArray("lines")
        numLogErrors = store.getInt("numLogErrors")
        numLogWarnings = store.getInt("numLogWarnings")
    }
}

// Note that this is set when log is called for the first time.
fileprivate let startTime = Date().timeIntervalSince1970 - 0.00001  // subtract a tiny time so we don't print a -0.0 timestamp
