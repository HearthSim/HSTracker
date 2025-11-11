//
//  RegularExpression.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

public struct Match {
    public var range: Range<String.Index>
    public var value: String
}

public struct Regex {
    let regex: NSRegularExpression

    init(_ expression: String) {
        do {
            try regex = NSRegularExpression(pattern: expression)
        } catch {
            preconditionFailure("Illegal regular expression: \(expression).")
        }
    }

    public func match(_ someString: String) -> Bool {
        let range = NSRange(location: 0, length: someString.count)
        let matches = regex.numberOfMatches(in: someString,
                                            options: [],
                                            range: range)
        return matches > 0
    }

    public func matches(_ someString: String) -> [Match] {
        var matches = [Match]()
        let range = NSRange(location: 0, length: someString.count)
        let results = regex.matches(in: someString,
                                    options: [],
                                    range: range)
        for result in results {
            for index in 1 ..< result.numberOfRanges {
                let resultRange = result.range(at: index)
                if let range = Range(resultRange, in: someString) {
                    let value = String(someString[range])
                    let match = Match(range: range, value: value)
                    matches.append(match)
                }
            }
        }
        return matches
    }
}

public extension String {

    func replace(_ pattern: Regex, with: String) -> String {
        let range = NSRange(location: 0, length: self.count)
        return pattern.regex.stringByReplacingMatches(in: self,
                                                      options: [],
                                                      range: range,
                                                      withTemplate: with)
    }

    @discardableResult
    func replace(_ pattern: Regex, using: (String, [Match]) -> String) -> String {
        let matches = pattern.matches(self)
        return using(self, matches)
    }

    @discardableResult
    func replace(_ patterns: [Regex], with string: String) -> String {
        return replace(patterns, with: [String](repeating: string, count: patterns.count))
    }

    @discardableResult
    func replace(_ patterns: [Regex], with strings: [String]) -> String {
        let merged = Array(zip(patterns, strings))
        var str = self
        for (pattern, string) in merged {
            str = str.replace(pattern, with: string)
        }
        return str
    }
    
    @discardableResult
    func replace(_ pattern: String, with string: String) -> String {
        if #available(macOS 13.0, *) {
            return self.replacing(pattern, with: string)
        } else {
            return self.replacingOccurrences(of: pattern, with: string)
        }
    }
}
