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

    init(expression: String) {
        self.expression = expression
    }

    func match(_ someString: String) -> Bool {
        do {
            let regularExpression = try NSRegularExpression(pattern: expression, options: [])
            let range = NSRange(location: 0, length: someString.characters.count)
            let matches = regularExpression.numberOfMatches(in: someString,
                                                                    options: [],
                                                                    range: range)
            return matches > 0
        } catch { return false }
    }

    func matches(_ someString: String) -> [Match] {
        var matches = [Match]()
        do {
            let regularExpression = try NSRegularExpression(pattern: expression, options: [])
            let range = NSRange(location: 0, length: someString.characters.count)
            let results = regularExpression.matches(in: someString,
                                                            options: [],
                                                            range: range)
            for result in results {
                for index in 1 ..< result.numberOfRanges {
                    let resultRange = result.rangeAt(index)
                    let startPos = someString.characters
                        .index(someString.startIndex, offsetBy: resultRange.location)
                    let end = resultRange.location + resultRange.length
                    let endPos = someString.characters.index(someString.startIndex, offsetBy: end)
                    let range = startPos ..< endPos

                    let value = someString.substring(with: range)
                    let match = Match(range: range, value: value)
                    matches.append(match)
                }
            }
        } catch { }
        return matches
    }
}

extension String {
    func match(_ pattern: String) -> Bool {
        return Regex(expression: pattern).match(self)
    }

    func matches(_ pattern: String) -> [Match] {
        return Regex(expression: pattern).matches(self)
    }

    func replace(_ pattern: String, with: String) -> String {
        do {
            let regularExpression = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: self.characters.count)
            return regularExpression.stringByReplacingMatches(in: self,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: with)
        } catch { }
        return self
    }
}
