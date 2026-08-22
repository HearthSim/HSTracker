//
//  CardDefsBinary.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Binary re-encoding of HearthSim's `CardDefs.xml`, produced at build time by
/// `Tools/CardDefsCompiler` and read back by `Database.loadDatabase`.
///
/// The bundled XML is pinned by `HSTracker/cards-version.txt` and never changes
/// for a given build, so there is no reason to pay for parsing 100 MB of it on
/// every launch. The blob is a *transcoding*, not an interpretation: it carries
/// every `<Tag>` and `<ReferencedTag>` in document order plus the localized
/// strings for every language the XML ships, and nothing else. Which tag means
/// what stays in `Database.swift`, so the compiler never has to be kept in sync
/// with it.
///
/// Layout, all integers little-endian:
///
///     header        128 bytes
///     entities      entityCount * 32 bytes
///     tags          tagCount * 8 bytes - (id, value), id < 0 means ReferencedTag
///     locTagIds     locSlotCount * 4 bytes
///     idBlob        UTF-8 card ids
///     languageDir   languageCount * 24 bytes
///     per language  locSlotCount * 8 bytes of (offset, length), then a UTF-8 blob
///
/// Only the display language and enUS are ever read, so the other twelve string
/// sections stay unfaulted pages of the mapped file.
enum CardDefsFormat {
    /// "HSCD"
    static let magic: UInt32 = 0x4853_4344
    static let version: UInt32 = 1

    static let headerSize = 128
    static let entitySize = 32
    static let tagSize = 8
    static let locTagIdSize = 4
    static let languageEntrySize = 24
    static let stringEntrySize = 8

    /// `length` sentinel for a language element the XML simply does not carry,
    /// which has to stay distinct from a present-but-empty one: an absent
    /// `<deDE>` leaves `Card.name` at its default, an empty one blanks it.
    static let absentString = UInt32.max

    /// Language codes are the XML element names, which are all four ASCII
    /// characters, so they fit inline in the directory.
    static let languageCodeSize = 4
}

// MARK: - Writing

/// Accumulates a `CardDefs` blob. Used by the build-time compiler only; the app
/// never writes one.
final class CardDefsWriter {
    private var languages = [String]()
    private var languageIndexByCode = [String: Int]()

    private var entities = Data()
    private var tags = Data()
    private var locTagIds = Data()
    private var ids = Data()
    private var languageIndexes = [Data]()
    private var languageBlobs = [Data]()
    /// Card text repeats heavily across entities - tokens, golden copies, the
    /// same one-word keyword on hundreds of minions - so each language's blob
    /// stores every distinct string once.
    private var languageInterns = [[String: UInt32]]()
    /// Which languages the open localized slot has already been given a value
    /// for; the rest get an `absentString` entry when the slot closes.
    private var slotFilled = [Bool]()

    private var entityCount: UInt32 = 0
    private var tagCount: UInt32 = 0
    private var locSlotCount: UInt32 = 0

    private var openId = ""
    private var openDbfId: Int32 = 0
    private var openTagStart: UInt32 = 0
    private var openLocStart: UInt32 = 0

    func beginEntity(cardId: String, dbfId: Int32) {
        openId = cardId
        openDbfId = dbfId
        openTagStart = tagCount
        openLocStart = locSlotCount
    }

    func addTag(id: Int32, value: Int32) {
        append(id, to: &tags)
        append(value, to: &tags)
        tagCount += 1
    }

    /// `<ReferencedTag>` shares the tag stream so document order survives; the
    /// negated id is what tells the two apart on the way back in.
    func addReferencedTag(id: Int32) {
        addTag(id: -id, value: 0)
    }

    func beginLocalizedTag(id: Int32) {
        append(id, to: &locTagIds)
    }

    func addLocalized(language code: String, value: String) {
        let index = languageIndex(for: code)
        guard !slotFilled[index] else {
            return
        }
        let bytes = Array(value.utf8)
        let offset: UInt32
        if let interned = languageInterns[index][value] {
            offset = interned
        } else {
            offset = UInt32(languageBlobs[index].count)
            languageInterns[index][value] = offset
            languageBlobs[index].append(contentsOf: bytes)
        }
        append(offset, to: &languageIndexes[index])
        append(UInt32(bytes.count), to: &languageIndexes[index])
        slotFilled[index] = true
    }

    func endLocalizedTag() {
        for index in languages.indices where !slotFilled[index] {
            appendAbsent(to: &languageIndexes[index])
        }
        for index in slotFilled.indices {
            slotFilled[index] = false
        }
        locSlotCount += 1
    }

    func endEntity() {
        let idBytes = Array(openId.utf8)
        append(openDbfId, to: &entities)
        append(UInt32(ids.count), to: &entities)
        append(UInt32(idBytes.count), to: &entities)
        append(openTagStart, to: &entities)
        append(tagCount - openTagStart, to: &entities)
        append(openLocStart, to: &entities)
        append(locSlotCount - openLocStart, to: &entities)
        append(UInt32(0), to: &entities)
        ids.append(contentsOf: idBytes)
        entityCount += 1
    }

    func finish() -> Data {
        pad(&ids)

        let entityOffset = CardDefsFormat.headerSize
        let tagOffset = entityOffset + entities.count
        let locTagIdOffset = tagOffset + tags.count
        let idBlobOffset = locTagIdOffset + locTagIds.count
        let languageDirOffset = idBlobOffset + ids.count

        var cursor = languageDirOffset + languages.count * CardDefsFormat.languageEntrySize
        var indexOffsets = [Int]()
        var blobOffsets = [Int]()
        for index in languages.indices {
            pad(&languageBlobs[index])
            indexOffsets.append(cursor)
            cursor += languageIndexes[index].count
            blobOffsets.append(cursor)
            cursor += languageBlobs[index].count
        }

        var header = Data()
        append(CardDefsFormat.magic, to: &header)
        append(CardDefsFormat.version, to: &header)
        append(entityCount, to: &header)
        append(tagCount, to: &header)
        append(locSlotCount, to: &header)
        append(UInt32(languages.count), to: &header)
        append(UInt64(entityOffset), to: &header)
        append(UInt64(tagOffset), to: &header)
        append(UInt64(locTagIdOffset), to: &header)
        append(UInt64(idBlobOffset), to: &header)
        append(UInt64(ids.count), to: &header)
        append(UInt64(languageDirOffset), to: &header)
        header.append(Data(repeating: 0, count: CardDefsFormat.headerSize - header.count))

        var directory = Data()
        for (index, code) in languages.enumerated() {
            var code4 = Array(code.utf8)
            code4 += Array(repeating: 0, count: max(0, CardDefsFormat.languageCodeSize - code4.count))
            directory.append(contentsOf: code4.prefix(CardDefsFormat.languageCodeSize))
            append(UInt32(0), to: &directory)
            append(UInt64(indexOffsets[index]), to: &directory)
            append(UInt64(blobOffsets[index]), to: &directory)
        }

        var file = Data(capacity: cursor)
        file.append(header)
        file.append(entities)
        file.append(tags)
        file.append(locTagIds)
        file.append(ids)
        file.append(directory)
        for index in languages.indices {
            file.append(languageIndexes[index])
            file.append(languageBlobs[index])
        }
        return file
    }

    /// Languages are discovered from the XML rather than hardcoded. One that
    /// turns up late gets its index backfilled with the slots it missed.
    private func languageIndex(for code: String) -> Int {
        if let index = languageIndexByCode[code] {
            return index
        }
        let index = languages.count
        languages.append(code)
        languageIndexByCode[code] = index
        var backfill = Data()
        for _ in 0..<locSlotCount {
            appendAbsent(to: &backfill)
        }
        languageIndexes.append(backfill)
        languageBlobs.append(Data())
        languageInterns.append([:])
        slotFilled.append(false)
        return index
    }

    private func appendAbsent(to data: inout Data) {
        append(UInt32(0), to: &data)
        append(CardDefsFormat.absentString, to: &data)
    }

    private func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    /// Keeps the section that follows 8-byte aligned so the reader's loads stay
    /// cheap on every architecture.
    private func pad(_ data: inout Data) {
        let remainder = data.count % 8
        if remainder != 0 {
            data.append(Data(repeating: 0, count: 8 - remainder))
        }
    }
}

// MARK: - Reading

/// A single `<Entity>`. Only valid for the duration of the
/// `CardDefsReader.forEachEntity` callback that handed it out - it points
/// straight into the mapped file rather than copying anything.
struct CardDefsEntity {
    fileprivate let base: UnsafeRawPointer
    fileprivate let languages: UnsafePointer<CardDefsReader.LanguageSection>
    fileprivate let record: UnsafeRawPointer
    fileprivate let tagBase: UnsafeRawPointer
    fileprivate let locTagBase: UnsafeRawPointer
    fileprivate let idBase: UnsafeRawPointer

    var dbfId: Int { Int(load(record, 0, Int32.self)) }

    var cardId: String {
        let offset = Int(load(record, 4, UInt32.self))
        let length = Int(load(record, 8, UInt32.self))
        return string(idBase + offset, length)
    }

    var tagCount: Int { Int(load(record, 16, UInt32.self)) }

    /// Document-order tag. A negative `id` marks a `<ReferencedTag>`.
    func tag(at index: Int) -> (id: Int, value: Int) {
        let at = tagBase + (Int(load(record, 12, UInt32.self)) + index) * CardDefsFormat.tagSize
        return (Int(load(at, 0, Int32.self)), Int(load(at, 4, Int32.self)))
    }

    var localizedCount: Int { Int(load(record, 24, UInt32.self)) }

    func localizedTagId(at index: Int) -> Int {
        let slot = Int(load(record, 20, UInt32.self)) + index
        return Int(load(locTagBase, slot * CardDefsFormat.locTagIdSize, Int32.self))
    }

    /// `nil` when the XML has no element for that language on this tag, or when
    /// the caller has no index for the language at all.
    func localizedString(at index: Int, language: Int?) -> String? {
        guard let language else {
            return nil
        }
        let slot = Int(load(record, 20, UInt32.self)) + index
        let section = languages[language]
        let entry = section.index + slot * CardDefsFormat.stringEntrySize
        let length = load(entry, 4, UInt32.self)
        if length == CardDefsFormat.absentString {
            return nil
        }
        return string(section.blob + Int(load(entry, 0, UInt32.self)), Int(length))
    }
}

private func load<T: FixedWidthInteger>(_ pointer: UnsafeRawPointer, _ offset: Int, _ type: T.Type) -> T {
    T(littleEndian: pointer.loadUnaligned(fromByteOffset: offset, as: T.self))
}

private func string(_ pointer: UnsafeRawPointer, _ length: Int) -> String {
    if length == 0 {
        return ""
    }
    return String(decoding: UnsafeRawBufferPointer(start: pointer, count: length), as: UTF8.self)
}

/// Memory-maps a `CardDefs` blob and walks it. Nothing is copied out of the
/// mapping except the strings the caller actually asks for.
final class CardDefsReader {
    struct LanguageSection {
        let index: UnsafeRawPointer
        let blob: UnsafeRawPointer
    }

    private let data: Data
    let entityCount: Int
    let languageCodes: [String]

    private let entityOffset: Int
    private let tagOffset: Int
    private let locTagIdOffset: Int
    private let idBlobOffset: Int
    private let languageDirOffset: Int

    init?(url: URL) {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count >= CardDefsFormat.headerSize else {
            return nil
        }
        self.data = data

        var codes = [String]()
        var counts: (entities: Int, languages: Int)?
        var offsets = (entity: 0, tag: 0, locTagId: 0, idBlob: 0, languageDir: 0)
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.baseAddress,
                  load(base, 0, UInt32.self) == CardDefsFormat.magic,
                  load(base, 4, UInt32.self) == CardDefsFormat.version else {
                return
            }
            let entityCount = Int(load(base, 8, UInt32.self))
            let languageCount = Int(load(base, 20, UInt32.self))
            offsets.entity = Int(load(base, 24, UInt64.self))
            offsets.tag = Int(load(base, 32, UInt64.self))
            offsets.locTagId = Int(load(base, 40, UInt64.self))
            offsets.idBlob = Int(load(base, 48, UInt64.self))
            offsets.languageDir = Int(load(base, 64, UInt64.self))

            for index in 0..<languageCount {
                let entry = base + offsets.languageDir + index * CardDefsFormat.languageEntrySize
                let bytes = UnsafeRawBufferPointer(start: entry, count: CardDefsFormat.languageCodeSize)
                codes.append(String(decoding: bytes, as: UTF8.self))
            }
            counts = (entityCount, languageCount)
        }
        guard let counts, counts.languages == codes.count else {
            return nil
        }
        entityCount = counts.entities
        languageCodes = codes
        entityOffset = offsets.entity
        tagOffset = offsets.tag
        locTagIdOffset = offsets.locTagId
        idBlobOffset = offsets.idBlob
        languageDirOffset = offsets.languageDir
    }

    func languageIndex(of code: String) -> Int? {
        languageCodes.firstIndex(of: code)
    }

    /// Walks every entity in file order. The `CardDefsEntity` handed to `body`
    /// must not outlive the call.
    func forEachEntity(_ body: (CardDefsEntity) -> Void) {
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.baseAddress else {
                return
            }
            var sections = [LanguageSection]()
            for index in languageCodes.indices {
                let entry = base + languageDirOffset + index * CardDefsFormat.languageEntrySize
                sections.append(LanguageSection(index: base + Int(load(entry, 8, UInt64.self)),
                                                blob: base + Int(load(entry, 16, UInt64.self))))
            }
            sections.withUnsafeBufferPointer { languages in
                guard let languageBase = languages.baseAddress else {
                    return
                }
                for index in 0..<entityCount {
                    body(CardDefsEntity(base: base,
                                        languages: languageBase,
                                        record: base + entityOffset + index * CardDefsFormat.entitySize,
                                        tagBase: base + tagOffset,
                                        locTagBase: base + locTagIdOffset,
                                        idBase: base + idBlobOffset))
                }
            }
        }
    }
}
