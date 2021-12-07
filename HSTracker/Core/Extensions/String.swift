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
    func substring(from: Int) -> String {
        if from < 0 || from > self.count {
            print("from index \(from) out of bounds")
            return ""
        }

        return String(self[index(startIndex, offsetBy: from)...])
    }

    func substring(from: Int, to: Int) -> String {
        if from < 0 || from > self.count {
            print("from index \(from) out of bounds")
            return ""
        } else if to < 0 || to > self.count {
            print("to index \(to) out of bounds")
            return ""
        }
        let range = self.index(self.startIndex, offsetBy: from)
            ..< self.index(self.startIndex, offsetBy: to)
        return String(self[range])
    }

    func substring(from: Int, length: Int) -> String {
        if from < 0 || from > self.count {
            print("from index \(from) out of bounds")
            return ""
        } else if length < 0 || from + length > self.count {
            print("end index \(from + length) out of bounds")
            return ""
        }

        let startPos = self.index(self.startIndex, offsetBy: from)
        let endPos = self.index(self.startIndex, offsetBy: from + length)
        let range = startPos ..< endPos
        return String(self[range])
    }

    func char(at: Int) -> String {
        let c = (self as NSString).character(at: at)
        let s = NSString(format: "%c", c)
        return s as String
    }
    
    var htmlToAttributedString: NSMutableAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
}
