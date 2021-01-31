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
    func unwrap() -> U {
        switch self {
        case .left(_) : fatalError("unwrap of left either")
        case .right(let val): return val
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
