//  Created by Jesse Jones on 3/13/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

extension String {
    func isBlankOrEmpty() -> Bool {
        return self.isEmpty || self.all({$0.isWhitespace})
    }
}
