//
//  Regex.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 14/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Match {
    var range: Range<String.Index>
    var value: String
}

struct Regex {
    let expression: String

    init(_ expression: String) {
        self.expression = expression
    }

    func match(someString: String) -> Bool {
        do {
            let regularExpression = try NSRegularExpression(pattern: expression, options: [])
            let range = NSRange(location: 0, length: someString.characters.count)
            let matches = regularExpression.numberOfMatchesInString(someString,
                                                                    options: [],
                                                                    range: range)
            return matches > 0
        } catch { return false }
    }

    func matches(someString: String) -> [Match] {
        var matches = [Match]()
        do {
            let regularExpression = try NSRegularExpression(pattern: expression, options: [])
            let range = NSRange(location: 0, length: someString.characters.count)
            let results = regularExpression.matchesInString(someString,
                                                            options: [],
                                                            range: range)
            for result in results {
                for index in 1 ..< result.numberOfRanges {
                    let resultRange = result.rangeAtIndex(index)
                    let startPos = someString.startIndex.advancedBy(resultRange.location)
                    let end = resultRange.location + resultRange.length
                    let endPos = someString.startIndex.advancedBy(end)
                    let range = startPos ..< endPos

                    let value = someString.substringWithRange(range)
                    let match = Match(range: range, value: value)
                    matches.append(match)
                }
            }
        } catch { }
        return matches
    }
}

extension String {
    func match(pattern: String) -> Bool {
        return Regex(pattern).match(self)
    }

    func matches(pattern: String) -> [Match] {
        return Regex(pattern).matches(self)
    }

    func replace(pattern: String, with: String) -> String {
        do {
            let regularExpression = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: self.characters.count)
            return regularExpression.stringByReplacingMatchesInString(self,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: with)
        } catch { }
        return self
    }
}
