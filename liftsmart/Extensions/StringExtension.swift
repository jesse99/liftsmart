//  Created by Jesse Jones on 3/13/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation

extension String {
    func isBlankOrEmpty() -> Bool {
        return self.isEmpty || self.all({$0.isWhitespace})
    }

    func toFileName() -> String {
        var result = ""

        for ch in self {
            switch ch {
            // All we really should have to re-map is "/" but other characters can be annoying
            // in file names so we'll zap those too. List is from:
            // https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
            case "/", "\\", "?", "%", "*", ":", "|", "\"", "<", ">", ".", " ":
                result += "_"
            default:
                result.append(ch)
            }
        }

        return result
    }
}
