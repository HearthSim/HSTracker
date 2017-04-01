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
    func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        return trim().isEmpty
    }
}
extension Optional where Wrapped == String {
    var isBlank: Bool {
        return self?.isBlank ?? true
    }
}

extension String {

    func substringWithRange(_ start: Int, end: Int) -> String {
        if start < 0 || start > self.characters.count {
            print("start index \(start) out of bounds")
            return ""
        } else if end < 0 || end > self.characters.count {
            print("end index \(end) out of bounds")
            return ""
        }
        let range = self.characters.index(self.startIndex, offsetBy: start)
            ..< self.characters.index(self.startIndex, offsetBy: end)
        return self.substring(with: range)
    }

    func substringWithRange(_ start: Int, location: Int) -> String {
        if start < 0 || start > self.characters.count {
            print("start index \(start) out of bounds")
            return ""
        } else if location < 0 || start + location > self.characters.count {
            print("end index \(start + location) out of bounds")
            return ""
        }

        let startPos = self.characters.index(self.startIndex, offsetBy: start)
        let endPos = self.characters.index(self.startIndex, offsetBy: start + location)
        let range = startPos ..< endPos
        return self.substring(with: range)
    }

    func char(at: Int) -> String {
        let c = (self as NSString).character(at: at)
        let s = NSString(format: "%c", c)
        return s as String
    }
}
