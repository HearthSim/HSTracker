//
//  ReflectionHelperTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

// ReflectionHelper reads the classes and their conformances out of the module's Swift metadata
// sections instead of casting every class. These run the casts it replaced and check it finds
// the same classes, with the witness tables the runtime hands out for them.
final class ReflectionHelperTests: XCTestCase {
    private struct Expected {
        var mono = [MonoClassInitializer.Type]()
        var activeEffects = [EntityBasedEffect.Type]()
        var counters = [BaseCounter.Type]()
        var related = [ICardWithRelatedCards.Type]()
        var highlight = [ICardWithHighlight.Type]()
        var spellSchoolTutors = [ISpellSchoolTutor.Type]()
        var cardGenerators = [ICardGenerator.Type]()
    }

    private static var expected: Expected = {
        var result = Expected()
        var count: UInt32 = 0
        let classList = objc_copyClassList(&count)
        defer {
            free(UnsafeMutableRawPointer(classList))
        }
        for cl in UnsafeBufferPointer(start: classList, count: Int(count)) {
            let name = class_getName(cl)
            if memcmp(name, "HSTracker.", 10) != 0 {
                continue
            }
            let isAbstractPoolBase = ReflectionHelper.abstractPoolBaseClassNames.contains(String(cString: name).replacingOccurrences(of: "HSTracker.", with: ""))
            if let mcl = cl as? MonoClassInitializer.Type {
                result.mono.append(mcl)
            } else if let aecl = cl as? EntityBasedEffect.Type {
                result.activeEffects.append(aecl)
            } else if let dccl = cl as? BaseCounter.Type, cl != BaseCounter.self && cl != StatsCounter.self && cl != NumericCounter.self {
                result.counters.append(dccl)
            } else if let rccl = cl as? ICardWithRelatedCards.Type, rccl != ResurrectionCard.self, !isAbstractPoolBase {
                result.related.append(rccl)
            } else if let hccl = cl as? ICardWithHighlight.Type {
                result.highlight.append(hccl)
            }
            if let sstcl = cl as? ISpellSchoolTutor.Type {
                result.spellSchoolTutors.append(sstcl)
            }
            if let cgcl = cl as? ICardGenerator.Type, !isAbstractPoolBase {
                result.cardGenerators.append(cgcl)
            }
        }
        return result
    }()

    override class func setUp() {
        super.setUp()
        ReflectionHelper.initialize()
    }

    // An existential metatype is the type's metadata followed by its witness table.
    private func words<T>(_ metatype: T) -> String {
        let pair = unsafeBitCast(metatype, to: (UnsafeRawPointer, UnsafeRawPointer).self)
        return "\(pair.0) \(pair.1)"
    }

    private func assertSameProtocolTypes<T>(_ actual: [T], _ expected: [T], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(expected.isEmpty, file: file, line: line)
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        XCTAssertEqual(Set(actual.map(words)), Set(expected.map(words)), file: file, line: line)
    }

    private func assertSameClasses(_ actual: [AnyClass], _ expected: [AnyClass], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(expected.isEmpty, file: file, line: line)
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        XCTAssertEqual(Set(actual.map { NSStringFromClass($0) }), Set(expected.map { NSStringFromClass($0) }), file: file, line: line)
    }

    func testMonoClasses() {
        assertSameProtocolTypes(ReflectionHelper.getMonoClasses(), ReflectionHelperTests.expected.mono)
    }

    func testActiveEffectClasses() {
        assertSameClasses(ReflectionHelper.getActiveEffectClasses(), ReflectionHelperTests.expected.activeEffects)
    }

    func testCounterClasses() {
        assertSameClasses(ReflectionHelper.getCounterClasses(), ReflectionHelperTests.expected.counters)
    }

    func testRelatedClasses() {
        assertSameProtocolTypes(ReflectionHelper.getRelatedClases(), ReflectionHelperTests.expected.related)
    }

    func testHighlightClasses() {
        assertSameProtocolTypes(ReflectionHelper.getHighlightClasses(), ReflectionHelperTests.expected.highlight)
    }

    func testSpellSchoolTutorClasses() {
        assertSameProtocolTypes(ReflectionHelper.getSpellSchoolTutorClasses(), ReflectionHelperTests.expected.spellSchoolTutors)
    }

    func testCardGeneratorClasses() {
        assertSameProtocolTypes(ReflectionHelper.getCardGeneratorClasses(), ReflectionHelperTests.expected.cardGenerators)
    }
}
