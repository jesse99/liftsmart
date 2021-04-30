//  Created by Jesse Jones on 4/29/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

func ASSERT(_ predicate: Bool, _ prefix: String, file: StaticString = #file, line: UInt = #line)  {
    // Thread.callStackSymbols can be used to print a back trace but it only includes mangled names and instructions offsets
    // so it's rather annoying.
    if !predicate {
        let url = URL(fileURLWithPath: file.description)
        log(.Error, "\(prefix) failed at \(url.lastPathComponent):\(line)")
        saveLogs()
        precondition(false, file: file, line: line)
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
        saveLogs()
        precondition(false, file: file, line: line)
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
        saveLogs()
        precondition(false, file: file, line: line)
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
        saveLogs()
        precondition(false, file: file, line: line)
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
        saveLogs()
        precondition(false, file: file, line: line)
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
        saveLogs()
        precondition(false, file: file, line: line)
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
        saveLogs()
        precondition(false, file: file, line: line)
    }
}
