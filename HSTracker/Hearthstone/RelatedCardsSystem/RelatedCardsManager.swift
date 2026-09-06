//
//  RelatedCardsManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class RelatedCardsManager {
    private var relatedCards = [String: ICardWithRelatedCards]()
    private var highlightCards = [String: ICardWithHighlight]()
    private var spellSchoolTutorCards = [String: ISpellSchoolTutor]()
    var cardGeneratorCards = [String: ICardGenerator]()
    
    private func initializeRelatedCards() {
        let _cards = ReflectionHelper.getRelatedClases()
        
        for card in _cards {
            let cardWithRelatedCards = card.init()
            relatedCards[cardWithRelatedCards.getCardId()] = cardWithRelatedCards
        }
    }
    
    private func initializeHighlightCards() {
        let _cards = ReflectionHelper.getHighlightClasses()
        
        for card in _cards {
            let cardWithHighlight = card.init()
            highlightCards[cardWithHighlight.getCardId()] = cardWithHighlight
        }
    }
    
    private func initializeSpellSchoolTutorCards() {
        let _cards = ReflectionHelper.getSpellSchoolTutorClasses()
        
        for card in _cards {
            let cardWithSpellSchoolTutor = card.init()
            spellSchoolTutorCards[cardWithSpellSchoolTutor.getCardId()] = cardWithSpellSchoolTutor
        }
    }
    
    private func initializeCardGeneratorCards() {
        let _cards = ReflectionHelper.getCardGeneratorClasses()
        
        for card in _cards {
            let cardGenerator = card.init()
            cardGeneratorCards[cardGenerator.getCardId()] = cardGenerator
        }
    }
    
    public func reset() {
        if relatedCards.count == 0 {
            initializeRelatedCards()
        }
        if highlightCards.count == 0 {
            initializeHighlightCards()
        }
        if spellSchoolTutorCards.count == 0 {
            initializeSpellSchoolTutorCards()
        }
        if cardGeneratorCards.count == 0 {
            initializeCardGeneratorCards()
        }
    }
    
    public func getCardWithHighlight(_ cardId: String) -> ICardWithHighlight? {
        return highlightCards[cardId]
    }

    public func getCardWithRelatedCards(_ cardId: String) -> ICardWithRelatedCards? {
        return relatedCards[cardId]
    }

    // Discover/generation-pool cards (RelatedCardsSystem/Cards/Pools) are also plain
    // ICardWithRelatedCards - this narrows to just the ones that additionally expose
    // picks()/eventCount()/isWithReplacement(), i.e. the ones the Outfinder statistics
    // panel has enough information to compute a summary for.
    public func getCardWithRelatedCardsSummary(_ cardId: String) -> ICardWithRelatedCardsSummary? {
        return relatedCards[cardId] as? ICardWithRelatedCardsSummary
    }

    // Dynamic pools (evolve/devolve-style effects) recompute their summary from live game
    // state on every hover - see ICardWithDynamicRelatedCardsSummary.
    public func getCardWithDynamicRelatedCardsSummary(_ cardId: String) -> ICardWithDynamicRelatedCardsSummary? {
        return relatedCards[cardId] as? ICardWithDynamicRelatedCardsSummary
    }

    // True when cardId is an Outfinder pool card, i.e. one that would contribute a summary
    // rather than only a plain related-cards list.
    public func hasOutfinderSummary(_ cardId: String) -> Bool {
        return getCardWithRelatedCardsSummary(cardId) != nil || getCardWithDynamicRelatedCardsSummary(cardId) != nil
    }

    /// Ports the guard HDT repeats at every related-cards trigger:
    /// `cardWithRelatedCards is ICardWithRelatedCardsSummary or ICardWithDynamicRelatedCardsSummary
    /// && (!OutfinderEnabled || !OutfinderIn<surface>)`. An Outfinder pool card is suppressed
    /// entirely when the Outfinder is off for that surface, while a card that only carries a plain
    /// related-cards list keeps showing its grid - those are not the Outfinder.
    ///
    /// - Parameter surfaceEnabled: `Settings.outfinderInDeck` or `Settings.outfinderInHand`, per
    ///   the trigger this is called from.
    public func isOutfinderSuppressed(cardId: String, surfaceEnabled: Bool) -> Bool {
        guard !Settings.outfinderEnabled || !surfaceEnabled else { return false }
        return hasOutfinderSummary(cardId)
    }

    // Single entry point every related-cards tooltip call site uses right alongside
    // getCardWithRelatedCards/getRelatedCards: nil/nil/false for a plain related-cards
    // list, or the actual Outfinder summary when cardId is a pool-generation card.
    // Pass player (and hoveredEntity, when known) to also cover dynamic pools; without a
    // player, dynamic cards fall through to nil/nil/false the same as an unregistered card.
    //
    // HDT threads Config.Instance.OutfinderUsePercentages through from each call site; because
    // every HSTracker call site goes through this one entry point, the setting is read here
    // instead, which is the same thing with one less parameter to keep in sync.
    // swiftlint:disable:next large_tuple
    public func getPoolStatistics(cardId: String, relatedCards: [Card?], player: Player? = nil, hoveredEntity: Entity? = nil) -> (statistics: PoolStatistics?, summary: [String: String]?, hasLargePool: Bool) {
        let usePercentages = Settings.outfinderUsePercentages
        if let player = player, let dynamicCard = getCardWithDynamicRelatedCardsSummary(cardId) {
            var summary: [String: String]?
            var statistics: PoolStatistics?
            let count = dynamicCard.computeSummary(player: player, summary: &summary, statistics: &statistics, usePercentages: usePercentages, hoveredEntity: hoveredEntity, pool: nil)
            return (statistics, summary, count > RelatedCardsManager.largePoolThreshold)
        }

        guard let generator = getCardWithRelatedCardsSummary(cardId) else {
            return (nil, nil, false)
        }

        let pickConfig = PickConfig(batchSize: generator.picks(), eventCount: generator.eventCount(), isWithReplacement: generator.isWithReplacement())
        var summary: [String: String]?
        var statistics: PoolStatistics?
        let count = RelatedCardsManager.tryGetRelatedCardsSummary(relatedCards: relatedCards, pickConfig: pickConfig, result: &summary, statistics: &statistics, usePercentages: usePercentages)
        return (statistics, summary, count > RelatedCardsManager.largePoolThreshold)
    }

    public func getSpellSchoolTutor(_ cardId: String) -> ISpellSchoolTutor? {
        return spellSchoolTutorCards[cardId]
    }
    
    public func getCardGenerator(_ cardId: String) -> ICardGenerator? {
        return cardGeneratorCards[cardId]
    }
    
    public func getCardsOpponentMayHave(_ opponent: Player, _ gameType: GameType, _ format: FormatType) -> [Card] {
        return relatedCards.values.filter { card in card.shouldShowForOpponent(opponent: opponent) && card.isCardLegal(gameType: gameType, format: format) }
            .compactMap { card in Cards.by(cardId: card.getCardId()) }
    }

    // MARK: - Outfinder statistics

    static let largePoolThreshold = 20

    /// Populated only for premium/trial users; nil means free users still get medians and
    /// bars but no keyword-match percentages.
    static var relatedCardsSummaryKeywords: [String: Set<String>]?

    /// Ports HDT's RelatedCardsManager.LoadRelatedCardsSummaryKeywords() plus its
    /// GameEventHandler.LoadOutfinderKeywordsIfEntitled() caller: clear first, then refetch, so a
    /// user who loses entitlement between games doesn't keep stale keyword data.
    ///
    /// HDT gates this on OutfinderTrial.HasAccess and can fetch through three routes (OAuth for
    /// premium, X-Trial-Token for a mulligan-guide trial, an unauthenticated arena endpoint for a
    /// free arena trial). HSTracker has no OutfinderTrial equivalent, so only the premium route is
    /// wired here - the trial-token overload exists on HSReplayAPI and can be pointed at a token
    /// source if Outfinder trials are ever ported. Without entitlement the map stays nil, which is
    /// exactly what the summary and filter UI already treat as "no keyword data".
    @available(macOS 10.15, *)
    static func loadRelatedCardsSummaryKeywords() {
        relatedCardsSummaryKeywords = nil

        guard HSReplayAPI.isFullyAuthenticated, HSReplayAPI.accountData?.is_premium ?? false else {
            return
        }

        Task {
            guard let raw = await HSReplayAPI.getDiscoverPoolKeywords(), !raw.isEmpty else {
                return
            }
            relatedCardsSummaryKeywords = raw.mapValues { Set($0) }
            logger.info("Loaded \(raw.count) Outfinder keyword groups")
        }
    }

    static func clearRelatedCardsSummaryKeywords() {
        relatedCardsSummaryKeywords = nil
    }

    static func tryGetRelatedCardsSummary(
        relatedCards: [Card?],
        pickConfig: PickConfig,
        result: inout [String: String]?,
        statistics: inout PoolStatistics?,
        usePercentages: Bool = true
    ) -> Int {
        result = nil
        statistics = nil

        // Small pools still get a summary — the tooltip shows the card grid and the
        // statistics side by side when the pool has largePoolThreshold cards or fewer.
        if relatedCards.isEmpty {
            return 0
        }

        var costValues = [Int](repeating: 0, count: relatedCards.count)
        var attackValues = [Int](repeating: 0, count: relatedCards.count)
        var healthValues = [Int](repeating: 0, count: relatedCards.count)
        var cardCount = 0
        var minionCount = 0

        let keywords = relatedCardsSummaryKeywords
        var helper: [String: Int]? = keywords != nil ? [String: Int]() : nil

        for card in relatedCards {
            guard let card = card else { continue }
            costValues[cardCount] = card.cost
            cardCount += 1
            if card.type != .spell {
                attackValues[minionCount] = card.attack
                healthValues[minionCount] = card.health
                minionCount += 1
            }
            if let keywords = keywords {
                for (key, ids) in keywords where ids.contains(card.id) {
                    helper![key] = (helper![key] ?? 0) + 1
                }
            }
        }

        if cardCount == 0 {
            return 0
        }

        if let helper = helper, !helper.isEmpty {
            var summary = [String: String]()
            for (key, value) in helper.sorted(by: { $0.value > $1.value }) {
                let displayText = usePercentages
                    ? "\(formatPercent(calculatePercentage(target: value, total: cardCount, config: pickConfig)))%"
                    : "\(value)"
                summary[localizeKeywordName(key)] = displayText
            }
            result = summary
        }

        let medianCost = calculateMedian(costValues, cardCount)
        let medianAttack: Double? = minionCount > 0 ? calculateMedian(attackValues, minionCount) : nil
        let medianHealth: Double? = minionCount > 0 ? calculateMedian(healthValues, minionCount) : nil

        statistics = PoolStatistics(
            medianCostText: formatMedian(medianCost),
            medianAttackText: medianAttack.map { formatMedian($0) },
            medianHealthText: medianHealth.map { formatMedian($0) },
            costBars: buildBars(costValues, cardCount, medianCost),
            attackBars: medianAttack.map { buildBars(attackValues, minionCount, $0) },
            healthBars: medianHealth.map { buildBars(healthValues, minionCount, $0) }
        )

        return cardCount
    }

    /// Summary for relative-cost (evolve/devolve) pools: each bucket is the slice of the pool
    /// at one resulting cost, drawn from `drawCount` times (once per target that resolved to
    /// it). Bars and medians are computed over the union of the buckets — "what can I get" —
    /// while keyword percentages use the per-bucket mixture.
    ///
    /// `affectsAllTargets` is true when every target is transformed (Evolve): buckets combine
    /// as independent draws. It is false when exactly one unknown candidate is affected
    /// (Mutate, Bamboozle): the percentage is the draw-count-weighted average over the buckets.
    static func tryGetBucketedRelatedCardsSummary(
        buckets: [(pool: [Card], drawCount: Int)],
        batchSize: Int,
        isWithReplacement: Bool,
        affectsAllTargets: Bool,
        result: inout [String: String]?,
        statistics: inout PoolStatistics?,
        usePercentages: Bool = true
    ) -> Int {
        result = nil
        statistics = nil

        var unionCount = 0
        for bucket in buckets {
            unionCount += bucket.pool.count
        }
        if unionCount == 0 {
            return 0
        }

        var costValues = [Int](repeating: 0, count: unionCount)
        var attackValues = [Int](repeating: 0, count: unionCount)
        var healthValues = [Int](repeating: 0, count: unionCount)
        var cardCount = 0
        var minionCount = 0

        let keywords = relatedCardsSummaryKeywords
        var totalMatches: [String: Int]? = keywords != nil ? [String: Int]() : nil
        var bucketMatches: [String: [Int]]? = keywords != nil ? [String: [Int]]() : nil

        for (bucketIndex, bucket) in buckets.enumerated() {
            for card in bucket.pool {
                costValues[cardCount] = card.cost
                cardCount += 1
                if card.type != .spell {
                    attackValues[minionCount] = card.attack
                    healthValues[minionCount] = card.health
                    minionCount += 1
                }
                if let keywords = keywords {
                    for (key, ids) in keywords where ids.contains(card.id) {
                        totalMatches![key] = (totalMatches![key] ?? 0) + 1
                        var perBucket = bucketMatches![key] ?? [Int](repeating: 0, count: buckets.count)
                        perBucket[bucketIndex] += 1
                        bucketMatches![key] = perBucket
                    }
                }
            }
        }

        if cardCount == 0 {
            return 0
        }

        if let totalMatches = totalMatches, !totalMatches.isEmpty {
            var summary = [String: String]()
            for (key, value) in totalMatches.sorted(by: { $0.value > $1.value }) {
                let displayText: String
                if usePercentages {
                    let percentage = calculateBucketedPercentage(
                        matchesPerBucket: bucketMatches![key] ?? [Int](repeating: 0, count: buckets.count),
                        buckets: buckets,
                        batchSize: batchSize,
                        isWithReplacement: isWithReplacement,
                        affectsAllTargets: affectsAllTargets)
                    displayText = "\(formatPercent(percentage))%"
                } else {
                    displayText = "\(value)"
                }
                summary[localizeKeywordName(key)] = displayText
            }
            result = summary
        }

        let medianCost = calculateMedian(costValues, cardCount)
        let medianAttack: Double? = minionCount > 0 ? calculateMedian(attackValues, minionCount) : nil
        let medianHealth: Double? = minionCount > 0 ? calculateMedian(healthValues, minionCount) : nil

        statistics = PoolStatistics(
            medianCostText: formatMedian(medianCost),
            medianAttackText: medianAttack.map { formatMedian($0) },
            medianHealthText: medianHealth.map { formatMedian($0) },
            costBars: buildBars(costValues, cardCount, medianCost),
            attackBars: medianAttack.map { buildBars(attackValues, minionCount, $0) },
            healthBars: medianHealth.map { buildBars(healthValues, minionCount, $0) }
        )

        return cardCount
    }

    static func localizeKeywordName(_ rawKeyword: String) -> String {
        let key = "TheOutfinder_Keyword_\(rawKeyword)"
        let localized = String.localizedString(key, comment: "")
        return localized == key ? rawKeyword : localized
    }

    private static func formatMedian(_ value: Double) -> String {
        return value == value.rounded(.down) ? "\(Int(value))" : String(format: "%.1f", locale: Language.culture, value)
    }

    // Mirrors C#'s "{0:0.#}" format: round to at most 1 decimal, no trailing zero.
    private static func formatPercent(_ value: Float) -> String {
        let rounded = (Double(value) * 10).rounded() / 10
        return rounded == rounded.rounded(.down) ? "\(Int(rounded))" : String(format: "%.1f", locale: Language.culture, rounded)
    }

    private static func calculateMedian(_ values: [Int], _ count: Int) -> Double {
        if count == 0 {
            return 0
        }
        let scratch = Array(values[0..<count]).sorted()
        let mid = count / 2
        return count % 2 == 0 ? Double(scratch[mid - 1] + scratch[mid]) / 2.0 : Double(scratch[mid])
    }

    private static let standardCap = 7  // catch-all for the normal 0-based window  → "7+"
    private static let highCostCap = 10 // catch-all for shifted high-cost windows  → "10+"
    private static let maxBarHeight = 40.0

    private static func buildBars(_ values: [Int], _ count: Int, _ median: Double) -> [StatBar] {
        if count == 0 {
            return []
        }

        var minVal = max(0, values[0])
        var maxVal = max(0, values[0])
        for i in 1..<count {
            let v = max(0, values[i])
            if v < minVal { minVal = v }
            if v > maxVal { maxVal = v }
        }

        // Standard window (0-based, "7+"): single-cost pools and pools with min=0.
        // Shifted window (minVal-based, "10+"): multi-cost high-cost pools so each individual
        // value gets its own bar instead of collapsing into a single spike. The start is
        // clamped to the cap: a pool whose cheapest/smallest card is already past it (e.g.
        // costs 12 and 20) has nothing left to spread out and collapses into the single
        // "10+" bucket, instead of producing an empty or negative window.
        let bucketStart = (minVal == maxVal || minVal < 1) ? 0 : min(minVal, highCostCap)
        let cap = bucketStart == 0 ? standardCap : highCostCap
        let bucketCount = cap - bucketStart + 1 // start=0→8, start=5→6, start=10→1

        var freq = [Int](repeating: 0, count: bucketCount)
        for i in 0..<count {
            let offset = max(0, values[i]) - bucketStart
            freq[offset < 0 ? 0 : (offset < bucketCount - 1 ? offset : bucketCount - 1)] += 1
        }

        var maxCount = 0
        for f in freq where f > maxCount {
            maxCount = f
        }

        if maxCount == 0 {
            return []
        }

        let adjustedMedian = median - Double(bucketStart)
        let medianBucket = adjustedMedian >= Double(bucketCount - 1)
            ? bucketCount - 1
            : Int(max(0, adjustedMedian).rounded(.toNearestOrAwayFromZero))

        var bars = [StatBar]()
        bars.reserveCapacity(bucketCount)
        for i in 0..<bucketCount {
            let label = i < bucketCount - 1 ? "\(bucketStart + i)" : "\(cap)+"
            bars.append(StatBar(label: label, barHeight: maxBarHeight * Double(freq[i]) / Double(maxCount), isMedian: i == medianBucket))
        }
        return bars
    }

    /// Returns the probability (0–100) that at least one keyword match appears across all
    /// sampling events described by `config`.
    ///
    /// Two sampling models:
    ///
    /// With replacement (binomial) — used for random summons/casts where every draw starts
    /// from the full pool: P(no match per event) = ((total − target) / total) ^ batchSize
    ///
    /// Without replacement (hypergeometric) — used for Discover, where a batch of batchSize
    /// unique cards is drawn simultaneously:
    /// P(no match per event) = ∏(i=0..batchSize−1) (total−target−i) / (total−i)
    ///
    /// Both paths then raise per-event probability to eventCount to account for multiple
    /// independent events, then apply the complement rule.
    private static func calculatePercentage(target: Int, total: Int, config: PickConfig) -> Float {
        if total <= 0 || target <= 0 {
            return 0
        }
        if target >= total {
            return 100
        }

        let pNoMatchPerEvent = perEventNoMatchProbability(target: target, total: total, batchSize: config.batchSize, isWithReplacement: config.isWithReplacement)

        // Raise to eventCount: independent events each have the same per-event probability.
        let pNoMatchAllEvents = pow(pNoMatchPerEvent, Double(config.eventCount))

        return Float((1.0 - pNoMatchAllEvents) * 100.0)
    }

    private static func perEventNoMatchProbability(target: Int, total: Int, batchSize: Int, isWithReplacement: Bool) -> Double {
        if total <= 0 || target <= 0 {
            return 1.0
        }
        if target >= total {
            return 0.0
        }

        if isWithReplacement {
            // Binomial: each of batchSize draws is independent from the full pool.
            // P(no match in one draw) = (total − target) / total
            // P(no match across all batchSize draws) = that value ^ batchSize
            return pow(Double(total - target) / Double(total), Double(batchSize))
        }

        // Hypergeometric: draw batchSize unique cards without replacement.
        // P(no match) = C(total−target, batchSize) / C(total, batchSize)
        //             = ∏(i=0..batchSize−1) (total−target−i) / (total−i)
        var pNoMatch = 1.0
        for i in 0..<batchSize {
            if total - target - i <= 0 {
                // Remaining draws are guaranteed to hit a match.
                return 0.0
            }
            pNoMatch *= Double(total - target - i) / Double(total - i)
        }
        return pNoMatch
    }

    /// Probability (0–100) that at least one keyword match appears across the bucket draws.
    /// Each bucket b contributes drawCount_b independent events sampling only that bucket's
    /// pool.
    ///
    /// affectsAllTargets (Evolve — every target transforms):
    /// P(no match) = ∏_b PerEventNoMatch(b) ^ drawCount_b
    ///
    /// Single unknown target (Mutate, Bamboozle — exactly one candidate is affected, uniformly
    /// at random):
    /// P(match) = Σ_b (drawCount_b / totalDraws) · (1 − PerEventNoMatch(b))
    private static func calculateBucketedPercentage(
        matchesPerBucket: [Int],
        buckets: [(pool: [Card], drawCount: Int)],
        batchSize: Int,
        isWithReplacement: Bool,
        affectsAllTargets: Bool
    ) -> Float {
        if affectsAllTargets {
            var pNoMatch = 1.0
            for b in 0..<buckets.count {
                let perEvent = perEventNoMatchProbability(target: matchesPerBucket[b], total: buckets[b].pool.count, batchSize: batchSize, isWithReplacement: isWithReplacement)
                pNoMatch *= pow(perEvent, Double(buckets[b].drawCount))
            }
            return Float((1.0 - pNoMatch) * 100.0)
        }

        var totalDraws = 0
        for bucket in buckets {
            totalDraws += bucket.drawCount
        }
        if totalDraws == 0 {
            return 0
        }

        var pMatch = 0.0
        for b in 0..<buckets.count {
            let perEvent = perEventNoMatchProbability(target: matchesPerBucket[b], total: buckets[b].pool.count, batchSize: batchSize, isWithReplacement: isWithReplacement)
            pMatch += Double(buckets[b].drawCount) / Double(totalDraws) * (1.0 - perEvent)
        }
        return Float(pMatch * 100.0)
    }
}
