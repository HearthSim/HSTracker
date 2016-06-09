/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */

import Foundation

extension String {

    static func isNullOrEmpty(str: String?) -> Bool {
        return str == nil || str!.isEmpty
    }

    func startsWith(str: String) -> Bool {
        return self.hasPrefix(str)
    }

    func endsWith(str: String) -> Bool {
        return self.hasSuffix(str)
    }

    func substringWithRange(start: Int, end: Int) -> String {
        if start < 0 || start > self.characters.count {
            print("start index \(start) out of bounds")
            return ""
        } else if end < 0 || end > self.characters.count {
            print("end index \(end) out of bounds")
            return ""
        }
        let range = self.startIndex.advancedBy(start) ..< self.startIndex.advancedBy(end)
        return self.substringWithRange(range)
    }

    func substringWithRange(start: Int, location: Int) -> String {
        if start < 0 || start > self.characters.count {
            print("start index \(start) out of bounds")
            return ""
        } else if location < 0 || start + location > self.characters.count {
            print("end index \(start + location) out of bounds")
            return ""
        }

        let startPos = self.startIndex.advancedBy(start)
        let endPos = self.startIndex.advancedBy(start + location)
        let range = startPos ..< endPos
        return self.substringWithRange(range)
    }
}
