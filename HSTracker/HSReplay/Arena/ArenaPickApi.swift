//
//  ArenaPickApi.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// MARK: - hero_pick

struct ArenaHeroPickApiResponse: Decodable {
    var data: [ResponseData]

    struct ResponseData: Decodable {
        var deck_class: Int
        var tier: String?
        var abandon_rate: Float?
        var pick_rate: Float?
        var num_drafts: Int?
        var popularity: Float?
        var win_rate: Float?
        var latest_winning_deckstrings: [String]?
        var class_deck_signature: ClassDeckSignature?
    }
}

struct ClassDeckSignature: Decodable {
    var data: [String: DeckSignatureEntry]
    var header: String
}

struct DeckSignatureEntry: Decodable {
    var ppc: Double?
    var arenasmith: Double?

    enum CodingKeys: String, CodingKey {
        case ppc = "12+ PPC"
        case arenasmith = "Arenasmith"
    }
}

// MARK: - card_pick

struct ArenaCardPickApiResponse: Decodable {
    var data: [String: CardStatsEntry]

    struct CardStatsEntry: Decodable {
        var arenasmith: ArenasmithScore?
        var arenasmith_dyn: ArenasmithDynScore?
        var related_cards: RelatedCardsBlock?
        var messages: [ArenaPickMessage]?
        var messages_old: [String: [String]]?
    }

    /// HDT declares `score` as a string, but the service sends it as a JSON
    /// number. Newtonsoft coerces one to the other without comment; `JSONDecoder`
    /// raises a `typeMismatch` that discards the whole response, so the decode is
    /// spelled out rather than synthesized.
    struct ArenasmithScore: Decodable {
        var score: String?
        var plaque: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ArenasmithScoreKeys.self)
            score = try container.decodeNumericStringIfPresent(forKey: .score)
            plaque = try container.decodeIfPresent(Int.self, forKey: .plaque)
        }
    }

    struct ArenasmithDynScore: Decodable {
        var score: String?
        var plaque: Int?
        var caution: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ArenasmithDynScoreKeys.self)
            score = try container.decodeNumericStringIfPresent(forKey: .score)
            plaque = try container.decodeIfPresent(Int.self, forKey: .plaque)
            caution = try container.decodeIfPresent(String.self, forKey: .caution)
        }
    }

    struct RelatedCardsBlock: Decodable {
        var generated_card_ids: GeneratedCardIdsBlock?
        var enhanced_by_card_ids: RelationSetBlock?
        var card_ids_enabled: RelationSetBlock?
    }

    struct GeneratedCardIdsBlock: Decodable {
        var generated: [String]?
        var total_cards: Int?
        var is_sorted: Bool?
    }

    struct RelationSetBlock: Decodable {
        var direct: [String]?
        var indirect: [String]?
        var total_cards: Int?

        var all: [String] { (direct ?? []) + (indirect ?? []) }
    }
}

// Declared at file scope rather than inside the records they belong to: nesting
// them alongside the types that already sit inside `ArenaCardPickApiResponse`
// would put them three levels deep.
private enum ArenasmithScoreKeys: String, CodingKey {
    case score, plaque
}

private enum ArenasmithDynScoreKeys: String, CodingKey {
    case score, plaque, caution
}

// MARK: - messages

enum ArenaPickMessageType: String, Decodable {
    case invalid = "INVALID"
    case enhancedBy = "ENHANCED_BY"
    case cardsEnabled = "CARDS_ENABLED"
    case offeredCopy = "OFFERED_COPY"
    case lowSynergy = "LOW_SYNERGY"
    case highlander = "HIGHLANDER"
    case softHighlander = "SOFT_HIGHLANDER"
    case highlanderChances = "HIGHLANDER_CHANCES"
    case veryRare = "VERY_RARE"
    case scoreBoost = "SCORE_BOOST"
    case questHelps = "QUEST_HELPS"
    case questNumReq = "QUEST_NUM_REQ"
}

/// One advisory line attached to an offered card.
///
/// HDT keeps `content` as a loose dictionary and re-serializes it to re-parse as a
/// typed record. Here the type is read first and the payload decoded directly into
/// the matching case, which avoids the round trip. Unknown or malformed types
/// decode to `.invalid` rather than throwing, matching HDT's `MessageTypeConverter`.
struct ArenaPickMessage: Decodable {
    let type: ArenaPickMessageType
    let content: Content

    enum Content {
        case enhancedBy(EnhancedByContent)
        case lowSynergy(LowSynergyContent)
        case highlander(HighlanderContent)
        case veryRare(VeryRareContent)
        case questHelps(QuestHelpsContent)
        case none
    }

    struct EnhancedByContent: Decodable {
        var predicates: [String]?
        var ideal_num_enhancers: Int?
        var deck_count: Int?
        var deck_count_generates: Int?
        var pool_count: Int?
        var pool_count_generates: Int?
        var odds_remaining_picks: Int?
        var odds_1: Int?
        var odds_2: Int?
        var odds_3: Int?
    }

    struct LowSynergyContent: Decodable {
        var remaining_picks: Int?
    }

    struct HighlanderContent: Decodable {
        var highlander_card_id: String?
    }

    struct VeryRareContent: Decodable {
        var percent_drafts: Double?
    }

    struct QuestHelpsContent: Decodable {
        var quest_card_id: String?
    }

    enum CodingKeys: String, CodingKey {
        case type, content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decodeIfPresent(String.self, forKey: .type)
        type = ArenaPickMessageType(rawValue: rawType?.uppercased() ?? "") ?? .invalid

        func decodeContent<T: Decodable>(_: T.Type) -> T? {
            try? container.decodeIfPresent(T.self, forKey: .content)
        }

        switch type {
        case .enhancedBy:
            content = decodeContent(EnhancedByContent.self).map { .enhancedBy($0) } ?? .none
        case .lowSynergy:
            content = decodeContent(LowSynergyContent.self).map { .lowSynergy($0) } ?? .none
        case .highlander, .softHighlander:
            content = decodeContent(HighlanderContent.self).map { .highlander($0) } ?? .none
        case .veryRare:
            content = decodeContent(VeryRareContent.self).map { .veryRare($0) } ?? .none
        case .questHelps:
            content = decodeContent(QuestHelpsContent.self).map { .questHelps($0) } ?? .none
        default:
            content = .none
        }
    }
}

// MARK: - score_deck

struct ArenaCardStats: Decodable {
    var data: [String: ArenaCardStatsEntry]
}

struct ArenaCardStatsEntry: Decodable {
    var score: Double?
}

// MARK: - trials & availability

struct ArenaTrialStatus: Decodable {
    var starter_trials_remaining: Int?
    var recurring_trials_remaining: Int?
    var max_recurring_trials: Int?
    var hours_til_next_reset: Int?
    var resumable_deck_ids: [Int64]?
}

struct ArenasmithStatus: Decodable {
    var data: [String: GameModeStatus]?

    struct GameModeStatus: Decodable {
        var arenasmith: Bool?
    }
}

// MARK: - packages

struct ArenaPackages: Decodable {
    var data: ArenaPackagesData?

    struct ArenaPackagesData: Decodable {
        var packages_by_key_card: [String: [String]]?
        var packages_from_package_only_cards: [String: String]?
    }
}

/// Reads a field the API may send either as a string or as a number.
///
/// The Arenasmith score arrives as a JSON number while everything downstream -
/// `formatScore`, which splits on the decimal point, and `Float(_:)` - is written
/// against HDT's string. Rendering a whole number without a fractional part gives
/// those the same text Newtonsoft hands HDT.
fileprivate extension KeyedDecodingContainer {
    func decodeNumericStringIfPresent(forKey key: Key) throws -> String? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let string = try? decode(String.self, forKey: key) {
            return string
        }
        let number = try decode(Double.self, forKey: key)
        guard number == number.rounded(), number.magnitude < 1e15 else {
            return String(number)
        }
        return String(Int(number))
    }
}
