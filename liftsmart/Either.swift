//  Created by Jesse Jones on 9/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

/// A type representing an alternative of one of two types.
///
/// By convention, and where applicable, `Left` is used to indicate failure, while `Right` is used to indicate success. (Mnemonic: “right” is a synonym for “correct.”)
///
/// Otherwise, it is implied that `Left` and `Right` are effectively unordered alternatives of equal standing.
public enum Either<T, U> {
    case left(T)
    case right(U)
}

extension Either {
    /// Return the right value or fatal error if self isn't right.
    func unwrap() -> U {    // TODO: rename this right?
        switch self {
        case .left(_): fatalError("unwrap of left either")
        case .right(let val): return val
        }
    }
    
    func left() -> T {
        switch self {
        case .left(let val): return val
        case .right(_): fatalError("unwrap of left either")
        }
    }
    
    func isLeft() -> Bool {
        switch self {
        case .left(_): return true
        case .right(_): return false
        }
    }
    
    func isRight() -> Bool {
        switch self {
        case .left(_): return false
        case .right(_): return true
        }
    }
    
    func map<R>(left: (T) -> R, right: (U) -> R) -> R {
        switch self {
        case .left(let t): return left(t)
        case .right(let u): return right(u)
        }
    }
}

/// These are for the case where we have several Either values and want to extract either the values
///or an accumulated error string.
func coalesce<R1, R2>(_ e1: Either<String, R1>, _ e2: Either<String, R2>) -> Either<String, (R1, R2)> {
    if e1.isRight() && e2.isRight() {
        return .right((e1.unwrap(), e2.unwrap()))
    }
    
    var errors: [String] = []
    if e1.isLeft() {
        errors.append(e1.left())
    }
    if e2.isLeft() {
        errors.append(e2.left())
    }
    return .left(errors.joined(separator: " "))
}

func coalesce<R1, R2, R3>(_ e1: Either<String, R1>, _ e2: Either<String, R2>, _ e3: Either<String, R3>) -> Either<String, (R1, R2, R3)> {
    if e1.isRight() && e2.isRight() && e3.isRight() {
        return .right((e1.unwrap(), e2.unwrap(), e3.unwrap()))
    }
    
    var errors: [String] = []
    if e1.isLeft() {
        errors.append(e1.left())
    }
    if e2.isLeft() {
        errors.append(e2.left())
    }
    if e3.isLeft() {
        errors.append(e3.left())
    }
    return .left(errors.joined(separator: " "))
}

func coalesce<R1, R2, R3, R4>(_ e1: Either<String, R1>, _ e2: Either<String, R2>, _ e3: Either<String, R3>, _ e4: Either<String, R4>) -> Either<String, (R1, R2, R3, R4)> {
    if e1.isRight() && e2.isRight() && e3.isRight() && e4.isRight() {
        return .right((e1.unwrap(), e2.unwrap(), e3.unwrap(), e4.unwrap()))
    }
    
    var errors: [String] = []
    if e1.isLeft() {
        errors.append(e1.left())
    }
    if e2.isLeft() {
        errors.append(e2.left())
    }
    if e3.isLeft() {
        errors.append(e3.left())
    }
    if e4.isLeft() {
        errors.append(e4.left())
    }
    return .left(errors.joined(separator: " "))
}
