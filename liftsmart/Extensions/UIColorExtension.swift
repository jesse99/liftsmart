//  Created by Jesse Jones on 4/30/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import UIKit

// Based on https://binaryadventures.com/blog/snippet-of-the-week-lighter-and-darker-colors/
public extension UIColor {
    func lighten(byPercentage percentage: CGFloat = 0.1) -> UIColor? {
        return changedBrightness(byPercentage: percentage)
    }
    
    func darken(byPercentage percentage: CGFloat = 0.1) -> UIColor? {
        return changedBrightness(byPercentage: -percentage)
    }
    
    func tint(byPercentage percentage: CGFloat = 0.1) -> UIColor? {
        return changedSaturation(byPercentage: percentage)
    }
    
    func shade(byPercentage percentage: CGFloat = 0.1) -> UIColor? {
        return changedSaturation(byPercentage: -percentage)
    }

    private func hsba() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)? {
        var hue: CGFloat = .nan, saturation: CGFloat = .nan, brightness: CGFloat = .nan, alpha: CGFloat = .nan
        guard self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return nil
        }
        return (hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    private func changedBrightness(byPercentage perc: CGFloat) -> UIColor? {
        if perc == 0 {
            return self.copy() as? UIColor
        }
        guard let hsba = hsba() else {
            return nil
        }
        let percentage: CGFloat = min(max(perc, -1), 1)
        let newBrightness = min(max(hsba.brightness + percentage, -1), 1)
        return UIColor(hue: hsba.hue, saturation: hsba.saturation, brightness: newBrightness, alpha: hsba.alpha)
    }
    
    private func changedSaturation(byPercentage perc: CGFloat) -> UIColor? {
        if perc == 0 {
            return self.copy() as? UIColor
        }
        guard let hsba = hsba() else {
            return nil
        }
        let percentage: CGFloat = min(max(perc, -1), 1)
        let newSaturation = min(max(hsba.saturation + percentage, -1), 1)
        return UIColor(hue: hsba.hue, saturation: newSaturation, brightness: hsba.brightness, alpha: hsba.alpha)
    }
}
