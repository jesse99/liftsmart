//  Created by Jesse Jones on 1/9/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

extension Array {
    func at(_ i: Int) -> Element? {
        return i < self.count ? self[i] : nil
    }
}
