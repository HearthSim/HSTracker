//
//  LocalizationFormatTests.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest

@testable import HSTracker

/// String(format:) walks the format string and the argument list in lockstep,
/// so a translation that reorders the arguments - which reads better in Korean,
/// Chinese and Japanese, where the number usually comes before the noun -
/// silently changes which argument each specifier gets. Handing an Int to %@
/// makes CoreFoundation read it as an object pointer and the app traps, which
/// is what the mulligan guide tooltips did in Sentry HSTRACKER-31K.
///
/// Reordering is fine as long as the positions are spelled out (%1$@, %2$d).
/// These tests hold every translation to the same argument types, in the same
/// slots, as its source string.
class LocalizationFormatTests: XCTestCase {

    // MARK: - The catalogs that ship

    func testEveryTranslationTakesTheSameArgumentsAsItsSource() throws {
        let catalogs = try Self.catalogURLs()
        XCTAssertFalse(catalogs.isEmpty, "found no string catalogs under Translations/")

        for url in catalogs {
            for problem in try Self.problems(in: url) {
                XCTFail("\(url.lastPathComponent): \(problem)")
            }
        }
    }

    // MARK: - The checker itself

    func testSignatureReadsArgumentsInOrder() {
        XCTAssertEqual(Self.signature(of: "Top players keep %@ %d%% of the time"),
                       .arguments([.object, .integer]))
        XCTAssertEqual(Self.signature(of: "%1$@ kept %3$d times out of %2$d"),
                       .arguments([.object, .integer, .integer]))
        XCTAssertEqual(Self.signature(of: "%2$d%% of the time, %1$@"),
                       .arguments([.object, .integer]))
    }

    func testSignatureIgnoresEscapedAndStrayPercents() {
        // Nothing is substituted into either of these, so neither is a format
        // string: "90% certain" is prose, not a conversion.
        XCTAssertEqual(Self.signature(of: "It is 90% certain that this is prose"), .arguments([]))
        XCTAssertEqual(Self.signature(of: "100%% sure"), .arguments([]))
        XCTAssertEqual(Self.signature(of: "%d%% of %@"), .arguments([.integer, .object]))
    }

    func testSignatureRejectsMalformedFormats() {
        XCTAssertEqual(Self.signature(of: "%1$@ and %d"),
                       .malformed("mixes positional (%1$@) and plain (%@) specifiers"))
        XCTAssertEqual(Self.signature(of: "%1$@ and %3$d"),
                       .malformed("skips an argument: uses slots [1, 3]"))
        XCTAssertEqual(Self.signature(of: "%1$@ and %1$d"),
                       .malformed("argument 1 is used as both object and integer"))
        XCTAssertEqual(Self.signature(of: "%*d wide"),
                       .malformed("uses a * width or precision, which takes an extra argument"))
    }

    func testCheckerCatchesAReorderedTranslation() {
        // The exact shape of HSTRACKER-31K: ko moves the percentage in front of
        // the card name without saying which argument is which.
        let source = Self.signature(of: "Top players keep %@ %d%% of the time")
        let translation = Self.signature(of: "%d%% 비율로 %@을(를) 유지합니다")
        XCTAssertNotEqual(source, translation)

        let fixed = Self.signature(of: "%2$d%% 비율로 %1$@을(를) 유지합니다")
        XCTAssertEqual(source, fixed)
    }

    // MARK: - Reading the catalogs

    /// The catalogs are checked in the source tree rather than in a bundle:
    /// Xcode compiles an .xcstrings into per-language .strings, so the file a
    /// translator actually edits is only readable from the repository.
    private static func catalogURLs() throws -> [URL] {
        let translations = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // HSTrackerTests
            .deletingLastPathComponent()      // repository root
            .appendingPathComponent("Translations")

        guard let walker = FileManager.default.enumerator(at: translations,
                                                          includingPropertiesForKeys: nil) else {
            return []
        }
        return walker.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "xcstrings" }
            .sorted { $0.path < $1.path }
    }

    private static func problems(in url: URL) throws -> [String] {
        let data = try Data(contentsOf: url)
        let catalog = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let sourceLanguage = catalog["sourceLanguage"] as? String ?? "en"
        let strings = catalog["strings"] as? [String: Any] ?? [:]

        var problems = [String]()

        for key in strings.keys.sorted() {
            let entry = strings[key] as? [String: Any] ?? [:]
            let localizations = entry["localizations"] as? [String: Any] ?? [:]

            let source = values(in: localizations[sourceLanguage]).first ?? key
            let expected = signature(of: source)

            switch expected {
            case .malformed(let reason):
                problems.append("\(key) [\(sourceLanguage)] the source string \(reason)")
                continue
            case .arguments(let kinds) where kinds.isEmpty:
                // Not a format string, so nothing is substituted into it.
                continue
            case .arguments:
                break
            }

            for language in localizations.keys.sorted() where language != sourceLanguage {
                for value in values(in: localizations[language]) {
                    let actual = signature(of: value)
                    guard actual != expected else { continue }
                    switch actual {
                    case .malformed(let reason):
                        problems.append("\(key) [\(language)] \(reason)")
                    case .arguments(let kinds):
                        problems.append("\(key) [\(language)] takes \(describe(kinds)) "
                                        + "where the source takes \(describe(expected.kinds))")
                    }
                }
            }
        }

        return problems
    }

    /// Every string in a localization, including the plural and device
    /// variations, each of which carries its own format string.
    private static func values(in localization: Any?) -> [String] {
        guard let localization = localization as? [String: Any] else { return [] }

        var out = [String]()
        if let unit = localization["stringUnit"] as? [String: Any],
           let value = unit["value"] as? String {
            out.append(value)
        }
        for variation in (localization["variations"] as? [String: Any] ?? [:]).values {
            for nested in (variation as? [String: Any] ?? [:]).values {
                out.append(contentsOf: values(in: nested))
            }
        }
        return out
    }

    private static func describe(_ kinds: [ArgumentKind]) -> String {
        kinds.isEmpty ? "no arguments" : "[" + kinds.map { $0.rawValue }.joined(separator: ", ") + "]"
    }

    // MARK: - Parsing format strings

    enum ArgumentKind: String {
        case object, cString, double, integer
    }

    enum Signature: Equatable {
        case arguments([ArgumentKind])
        case malformed(String)

        var kinds: [ArgumentKind] {
            if case .arguments(let kinds) = self { return kinds }
            return []
        }
    }

    // Deliberately no space flag: "% d" is legal printf, nothing here uses it,
    // and allowing it would turn the stray percent of "90% certain" into a
    // conversion.
    private static let specifier = try! NSRegularExpression(
        pattern: #"%(?:(\d+)\$)?[-+#0]*(\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|q|L|z|j|t)?([@dDuUxXoOfFeEgGcCsSpaA])"#)

    static func signature(of value: String) -> Signature {
        let text = value as NSString
        let percent = ("%" as NSString).character(at: 0)

        var slots = [Int: ArgumentKind]()
        var sawPositional = false
        var sawPlain = false
        var nth = 0
        var index = 0

        while index < text.length {
            guard text.character(at: index) == percent else {
                index += 1
                continue
            }
            // %% is a literal percent, not a conversion.
            if index + 1 < text.length, text.character(at: index + 1) == percent {
                index += 2
                continue
            }
            let rest = NSRange(location: index, length: text.length - index)
            guard let match = specifier.firstMatch(in: value, options: .anchored, range: rest) else {
                // A stray percent. Only a problem if the string is used as a
                // format, which the catalog alone cannot tell us, so leave it.
                index += 1
                continue
            }
            index = match.range.location + match.range.length

            if text.substring(with: match.range).contains("*") {
                return .malformed("uses a * width or precision, which takes an extra argument")
            }

            let slot: Int
            if match.range(at: 1).location != NSNotFound {
                sawPositional = true
                slot = Int(text.substring(with: match.range(at: 1))) ?? 0
            } else {
                sawPlain = true
                nth += 1
                slot = nth
            }
            if sawPositional && sawPlain {
                return .malformed("mixes positional (%1$@) and plain (%@) specifiers")
            }

            let kind = Self.kind(of: text.substring(with: match.range(at: 3)))
            if let existing = slots[slot], existing != kind {
                return .malformed("argument \(slot) is used as both \(existing.rawValue) and \(kind.rawValue)")
            }
            slots[slot] = kind
        }

        let used = slots.keys.sorted()
        guard used.isEmpty || used == Array(1...used.count) else {
            return .malformed("skips an argument: uses slots \(used)")
        }
        return .arguments(used.compactMap { slots[$0] })
    }

    private static func kind(of conversion: String) -> ArgumentKind {
        switch conversion {
        case "@":
            return .object
        case "s", "S":
            return .cString
        case "f", "F", "e", "E", "g", "G", "a", "A":
            return .double
        default:
            return .integer
        }
    }
}
