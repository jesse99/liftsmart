//  DoubleExtensions.swift
//  liftsmart
//
//  Created by Jesse Jones on 4/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Foundation

extension Double {
    func isNearlyEqual(_ rhs: Double) -> Bool {
        if self.isNaN && rhs.isNaN {
            // NaNs compare false with everything, inluding themselves.
            return false
        }
        if (self.isInfinite && self > 0.0) && (rhs.isInfinite && rhs > 0.0) {
            return true
        }
        if (self.isInfinite && self < 0.0) && (rhs.isInfinite && rhs < 0.0) {
            return true
        }
        
        // Our numbers are percents and weights so we can use a relatively large epsilon.
        return abs(self - rhs) < 0.001
    }
}


