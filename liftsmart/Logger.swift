//  Created by Jesse Jones on 4/18/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

enum LogLevel: Int {case Error; case Warning; case Info; case Debug}

struct LogLine {
    let seconds: TimeInterval   // since program started
    let level: LogLevel
    let line: String
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
    let entry = LogLine(seconds: elapsed, level: level, line: message)
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

func ASSERT(_ predicate: Bool, _ prefix: String, file: StaticString = #file, line: UInt = #line)  {
    // Thread.callStackSymbols can be used to print a back trace but it only includes mangled names and instructions offsets
    // so it's rather annoying.
    if !predicate {
        let url = URL(fileURLWithPath: file.description)
        log(.Error, "\(prefix) failed at \(url.lastPathComponent):\(line)")
//        precondition(false, file: file, line: line)
    }
}

func ASSERT_EQ<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if lhs != rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            log(.Error, "\(prefix) \(lhs) == \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            log(.Error, "\(lhs) == \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
//        precondition(false, file: file, line: line)
    }
}

func ASSERT_NE<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if lhs == rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            log(.Error, "\(prefix) \(lhs) != \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            log(.Error, "\(lhs) != \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
//        precondition(false, file: file, line: line)
    }
}

func ASSERT_LE<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Comparable {
    if lhs > rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            log(.Error, "\(prefix) \(lhs) <= \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            log(.Error, "\(lhs) <= \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
//        precondition(false, file: file, line: line)
    }
}

func ASSERT_GE<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Comparable {
    if lhs < rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            log(.Error, "\(prefix) \(lhs) >= \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            log(.Error, "\(lhs) >= \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
//        precondition(false, file: file, line: line)
    }
}

func ASSERT_NIL<T>(_ value: T?, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if let v = value {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            log(.Error, "\(prefix) \(v) == nil failed at \(url.lastPathComponent):\(line)")
        } else {
            log(.Error, "\(v) == nil failed at \(url.lastPathComponent):\(line)")
        }
//        precondition(false, file: file, line: line)
    }
}

func ASSERT_NOT_NIL<T>(_ value: T?, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if value == nil {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            log(.Error, "\(prefix) not nil failed at \(url.lastPathComponent):\(line)")
        } else {
            log(.Error, "not nil failed at \(url.lastPathComponent):\(line)")
        }
//        precondition(false, file: file, line: line)
    }
}

// Note that this is set when log is called for the first time.
fileprivate let startTime = Date().timeIntervalSince1970 - 0.00001  // subtract a tiny time so we don't print a -0.0 timestamp
