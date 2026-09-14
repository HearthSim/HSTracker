//
//  RegionDrawer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Port of HDT's Utility/RegionDrawer/RegionDrawer.cs.
//
// Works out where Hearthstone itself draws a card, a tooltip, an enchantment
// list, the escape menu and so on, so the overlay can be punched through
// there - see OverlayOpacityMask. Every rect it returns is normalized to the
// overlay canvas: 0..1 on both axes with y pointing down, matching WPF's Rect
// (and SwiftUI's own coordinate space).
class RegionDrawer {
    private static let baseHeight = 1080.0

    private static let cardHeight = 0.39
    private static let cardAspectRatio = 28 / (cardHeight * 100)

    private static let heroPowerHeight = 0.42
    private static let heroPowerAspectRatio = 24 / (heroPowerHeight * 100)
    private static let bgsHeroPowerHeight = 0.39
    private static let bgsHeroPowerAspectRatio = 28 / (bgsHeroPowerHeight * 100)

    private static let enchantHeightFactor = 0.07
    private static let enchantWidth = 215.0
    private static let cardToEnchantOffsetX = 0.035

    private static let tooltipHeightFactor = 0.08
    private static let tooltipWidth = 220.0
    private static let cardToToolTipOffsetX = 0.23
    private static let cardToToolTipOffsetY = 0.025

    private static let handCardToToolTipOffsetX = 0.275
    private static let handCardHeight = 0.5
    private static let handCardAspectRatio = 34 / (handCardHeight * 100)
    private static let handTooltipWidth = 230.0

    private static let secretCardHeight = 0.43
    private static let weaponCardHeight = 0.37
    private static let weaponToToolTipOffsetX = 0.21

    private static let trinketHeight = 0.365
    private static let trinketToToolTipOffsetX = 0.2
    private static let trinketAspectRatio = 25 / (trinketHeight * 100)

    private static let bgHeroPickHeroWidth = 0.1725
    private static let bgHeroPickHeroXSpacing = 0.0635
    private static let bgHeroPickTooltipHeight = 0.32
    private static let bgHeroPickTooltipAspectRatio = 25 / (bgHeroPickTooltipHeight * 100)

    private static let anomalyHeight = 0.45
    private static let anomalyAspectRatio = 32 / (anomalyHeight * 100)

    // the big card frame extends about 0.065 above the card region, so this keeps its visual top at the screen edge
    private static let bigCardTopLimit = 0.06

    // dark gift choice cards render larger and spaced wider than regular discovers, with a banner of
    // varying height below each card (the region height is generous to cover the tallest banners)
    private static let darkGiftCardHeight = 0.605
    private static let darkGiftCardAspectRatio = 33.2 / (darkGiftCardHeight * 100)
    private static let darkGiftCardSpacing = 0.287
    private static let darkGiftCardY = 0.185

    // the escape menu is horizontally centered and its height varies with the number of buttons
    // (concede and restart only exist during a match), so this covers the tallest variant
    private static let gameMenuHeight = 0.36
    private static let gameMenuWidth = 0.37
    private static let gameMenuTop = 0.25

    private let height: Double
    private let width: Double
    private let screenRatio: Double

    init(height: Double, width: Double, screenRatio: Double) {
        self.height = height
        self.width = width
        self.screenRatio = screenRatio
    }

    func drawCardRegion(offsetX: Double, offsetY: Double,
                        cardHeight: Double = RegionDrawer.cardHeight,
                        aspectRatio: Double = RegionDrawer.cardAspectRatio) -> CGRect {
        let heightScaling = height / RegionDrawer.baseHeight

        let heightInPixels = cardHeight * heightScaling * RegionDrawer.baseHeight
        let widthInPixels = heightInPixels * aspectRatio

        let normalizedHeight = heightInPixels / height
        let normalizedWidth = widthInPixels / width

        let posX = SizeHelper.getScaledXPos(offsetX, width: width, ratio: screenRatio) / width
        let posY = offsetY

        return CGRect(x: posX, y: posY, width: normalizedWidth, height: normalizedHeight)
    }

    func drawFriendsListRegion() -> CGRect {
        let heightScaling = height / RegionDrawer.baseHeight

        let heightInPixels = 0.68 * heightScaling * RegionDrawer.baseHeight
        let widthInPixels = 0.38 * heightScaling * RegionDrawer.baseHeight

        let normalizedHeight = heightInPixels / height
        let normalizedWidth = widthInPixels / width

        return CGRect(x: 0, y: 0.27, width: normalizedWidth, height: normalizedHeight)
    }

    func drawGameMenuRegion() -> CGRect {
        let heightScaling = height / RegionDrawer.baseHeight

        let heightInPixels = RegionDrawer.gameMenuHeight * heightScaling * RegionDrawer.baseHeight
        let widthInPixels = RegionDrawer.gameMenuWidth * heightScaling * RegionDrawer.baseHeight

        let normalizedHeight = heightInPixels / height
        let normalizedWidth = widthInPixels / width

        return CGRect(x: 0.5 - normalizedWidth / 2, y: RegionDrawer.gameMenuTop,
                      width: normalizedWidth, height: normalizedHeight)
    }

    func drawHeroPowerRegion(offsetX: Double, offsetY: Double,
                             heroPowerHeight: Double = RegionDrawer.heroPowerHeight,
                             heroAspectRatio: Double = RegionDrawer.heroPowerAspectRatio) -> CGRect {
        let heightScaling = height / RegionDrawer.baseHeight

        let heightInPixels = heroPowerHeight * heightScaling * RegionDrawer.baseHeight
        let widthInPixels = heightInPixels * heroAspectRatio

        let normalizedHeight = heightInPixels / height
        let normalizedWidth = widthInPixels / width

        let posX = SizeHelper.getScaledXPos(offsetX, width: width, ratio: screenRatio) / width
        let posY = offsetY

        return CGRect(x: posX, y: posY, width: normalizedWidth, height: normalizedHeight)
    }

    func drawCardTooltipRegion(offsetX: Double, offsetY: Double, height tooltipHeight: Double,
                               tooltipWidth: Double = RegionDrawer.tooltipWidth) -> CGRect {
        let heightScaling = height / RegionDrawer.baseHeight

        let heightInPixels = RegionDrawer.tooltipHeightFactor * heightScaling * RegionDrawer.baseHeight * tooltipHeight
        let widthInPixels = tooltipWidth * heightScaling

        let normalizedHeight = heightInPixels / height
        let normalizedWidth = widthInPixels / width

        let posX = SizeHelper.getScaledXPos(offsetX, width: width, ratio: screenRatio) / width
        let posY = offsetY + RegionDrawer.cardToToolTipOffsetY

        return CGRect(x: posX, y: posY, width: normalizedWidth, height: normalizedHeight)
    }

    func drawCardEnchantRegion(offsetX: Double, offsetY: Double, height enchantHeight: Double) -> CGRect {
        let heightScaling = height / RegionDrawer.baseHeight

        let heightInPixels = RegionDrawer.enchantHeightFactor * heightScaling * RegionDrawer.baseHeight * enchantHeight
        let widthInPixels = RegionDrawer.enchantWidth * heightScaling

        let normalizedHeight = heightInPixels / height
        let normalizedWidth = widthInPixels / width

        let posX = SizeHelper.getScaledXPos(offsetX + RegionDrawer.cardToEnchantOffsetX,
                                            width: width, ratio: screenRatio) / width
        let posY = offsetY + RegionDrawer.cardHeight

        return CGRect(x: posX, y: posY, width: normalizedWidth, height: normalizedHeight)
    }

    func drawBoardCardRegions(minionCount: Int, position: Int, isPlayerBoard: Bool,
                              tooltipHeight: Double, enchantHeight: Double) -> [CGRect] {
        let baseOffsetX = 0.2
        let baseOffsetY = 0.35
        var regions = [CGRect]()

        let centerPosition = Double(minionCount + 1) / 2.0

        // Calculate the offset for each minion based on its position relative to the center
        let relativePosition = Double(position) - centerPosition
        let offsetX = relativePosition >= -0.5
            ? baseOffsetX + relativePosition * 0.098
            : baseOffsetX + 0.375 + relativePosition * 0.098
        let offsetY = isPlayerBoard ? baseOffsetY : 0.175

        // Draw the regions for each minion using the calculated offsets
        var rectCard = drawCardRegion(offsetX: offsetX, offsetY: offsetY)
        let tooltipOffsetX = offsetX + RegionDrawer.cardToToolTipOffsetX
        var rectTooltip = drawCardTooltipRegion(
            offsetX: relativePosition <= 0.5 ? tooltipOffsetX : tooltipOffsetX - RegionDrawer.cardHeight,
            offsetY: offsetY, height: tooltipHeight)
        var rectEnchants = drawCardEnchantRegion(offsetX: offsetX, offsetY: offsetY, height: enchantHeight)

        // the game anchors an overflowing enchantment list to the screen bottom and pushes the card and tooltips up,
        // but keeps the card top on screen (BigCard.FitInsideScreenBottom, then FitInsideScreenTop)
        let overflow = rectEnchants.maxY - 1
        if overflow > 0 {
            let shift = min(overflow, max(rectCard.origin.y - RegionDrawer.bigCardTopLimit, 0))
            rectCard.origin.y -= shift
            rectTooltip.origin.y -= shift
            rectEnchants.origin.y -= shift
        }

        regions.append(rectCard)
        regions.append(rectTooltip)
        regions.append(rectEnchants)

        return regions
    }

    func drawSecretCardRegions(position: Int, isPlayerBoard: Bool, tooltipHeight: Double) -> [CGRect] {
        let baseOffsetX = 0.57
        let baseOffsetY = isPlayerBoard ? 0.445 : 0.0
        var regions = [CGRect]()

        let offsetYByLayer = [0.0, 0.030, 0.08]
        let leftOffsetXByLayer = [0.0, 0.037, 0.062]
        let rightOffsetXByLayer = [0.0, 0.034, 0.059]

        let centerPosition = 1

        // Calculate the offset for each secret based on its position relative to the center
        let relativePosition = position - centerPosition
        let isLeftSide = relativePosition % 2 != 0
        let layer = Int(ceil(Double(relativePosition) / 2.0))

        // Limit is 5 secrets
        if layer > 2 || layer < 0 {
            return regions
        }

        let offsetX = isLeftSide ? baseOffsetX - leftOffsetXByLayer[layer] : baseOffsetX + rightOffsetXByLayer[layer]
        let offsetY = baseOffsetY + (isPlayerBoard ? offsetYByLayer[layer] : 0)

        // Draw the regions for each secret using the calculated offsets
        let rectCard = drawCardRegion(offsetX: offsetX, offsetY: offsetY, cardHeight: RegionDrawer.secretCardHeight)
        let tooltipOffsetX = offsetX + RegionDrawer.handCardToToolTipOffsetX
        let rectTooltip = drawCardTooltipRegion(
            offsetX: relativePosition < 0 ? tooltipOffsetX : tooltipOffsetX - 0.44,
            offsetY: offsetY + 0.008, height: tooltipHeight * 1.08,
            tooltipWidth: RegionDrawer.handTooltipWidth)

        regions.append(rectCard)
        regions.append(rectTooltip)

        return regions
    }

    func drawHandCardRegions(cardCount: Int, position: Int, isPlayerBoard: Bool, cardType: CardType?,
                             tooltipHeight: Double, enchantHeight: Double) -> [CGRect] {
        if !isPlayerBoard {
            return [CGRect]()
        }

        // HDT compares Card.Type against the "Hero" display string here.
        let isHero = cardType == .hero

        let cardTotal: Double = cardCount > 10 ? Double(cardCount) : 10

        let baseOffsetX = 0.34
        let baseOffsetY = 1 - RegionDrawer.handCardHeight
        var regions = [CGRect]()

        let centerPosition = Double(cardCount + 1) / 2.0

        // Calculate the offset for each minion based on its position relative to the center
        let relativePosition = Double(position) - centerPosition
        let offsetXScale = cardCount > 3 ? cardTotal / Double(cardCount) * 0.037 : 0.098

        let offsetX = baseOffsetX + relativePosition * offsetXScale
        let offsetY = baseOffsetY

        // Draw the regions for each minion using the calculated offsets
        let tooltipOffsetX = offsetX + RegionDrawer.handCardToToolTipOffsetX

        let rectCard = drawCardRegion(offsetX: offsetX, offsetY: offsetY,
                                      cardHeight: RegionDrawer.handCardHeight,
                                      aspectRatio: RegionDrawer.handCardAspectRatio)

        var rectTooltip = drawCardTooltipRegion(
            offsetX: relativePosition < 0.5 ? tooltipOffsetX : tooltipOffsetX - 0.44,
            offsetY: offsetY + 0.008, height: tooltipHeight * 1.08,
            tooltipWidth: RegionDrawer.handTooltipWidth)

        if isHero {
            let isLeftSide = relativePosition >= 0.5
            rectTooltip = drawCardTooltipRegion(
                offsetX: isLeftSide ? tooltipOffsetX : tooltipOffsetX - 0.44,
                offsetY: offsetY + 0.008, height: tooltipHeight * 1.08,
                tooltipWidth: RegionDrawer.handTooltipWidth)

            let rectHeroPower = drawHeroPowerRegion(offsetX: isLeftSide ? offsetX - 0.22 : offsetX + 0.26,
                                                    offsetY: offsetY + 0.01,
                                                    heroPowerHeight: RegionDrawer.heroPowerHeight + 0.08)
            regions.append(rectHeroPower)
        }

        let rectEnchants = drawCardEnchantRegion(offsetX: offsetX, offsetY: offsetY, height: enchantHeight)
        regions.append(rectCard)
        regions.append(rectTooltip)
        regions.append(rectEnchants)

        return regions
    }

    func drawHeroPowerRegion(isPlayerBoard: Bool) -> CGRect {
        let baseOffsetX = 0.7
        let baseOffsetY = isPlayerBoard ? 0.57 : 0.04

        let rect = drawHeroPowerRegion(offsetX: baseOffsetX, offsetY: baseOffsetY,
                                       heroPowerHeight: isPlayerBoard
                                        ? RegionDrawer.heroPowerHeight + 0.02
                                        : RegionDrawer.heroPowerHeight)
        return rect
    }

    func drawWeaponRegions(isPlayerBoard: Bool, tooltipHeight: Double, enchantHeight: Double) -> [CGRect] {
        let baseOffsetX = isPlayerBoard ? 0.45 : 0.46
        let baseOffsetY = isPlayerBoard ? 0.575 : 0.035
        var regions = [CGRect]()

        // Draw the regions for each minion using the calculated offsets
        let rectCard = drawCardRegion(offsetX: baseOffsetX, offsetY: baseOffsetY,
                                      cardHeight: RegionDrawer.weaponCardHeight)
        let tooltipOffsetX = baseOffsetX + RegionDrawer.weaponToToolTipOffsetX

        let rectTooltip = drawCardTooltipRegion(offsetX: tooltipOffsetX, offsetY: baseOffsetY + 0.01,
                                                height: tooltipHeight)
        let rectEnchants = drawCardEnchantRegion(offsetX: baseOffsetX - 0.0075, offsetY: baseOffsetY - 0.02,
                                                 height: enchantHeight)

        regions.append(rectCard)
        regions.append(rectTooltip)
        regions.append(rectEnchants)

        return regions
    }

    func drawBgTrinketRegions(position: Int, hasAttachedCard: Bool, isPlayerBoard: Bool,
                              tooltipHeight: Double) -> [CGRect] {
        let baseOffsetX = 0.463
        let baseOffsetY = isPlayerBoard ? 0.525 : 0.0
        var regions = [CGRect]()

        let relativePosition = Double(position - 1)

        let offsetX = baseOffsetX - relativePosition * 0.0525
        let offsetY = isPlayerBoard
            ? baseOffsetY - relativePosition * 0.06
            : baseOffsetY - 0.02 + relativePosition * 0.01

        let rectCard = drawCardRegion(offsetX: offsetX, offsetY: offsetY,
                                      cardHeight: RegionDrawer.trinketHeight,
                                      aspectRatio: RegionDrawer.trinketAspectRatio)
        let tooltipOffsetX = hasAttachedCard ? offsetX - 0.17 : offsetX + RegionDrawer.trinketToToolTipOffsetX
        let rectTooltip = drawCardTooltipRegion(offsetX: tooltipOffsetX, offsetY: offsetY + 0.008,
                                                height: tooltipHeight * 1.08,
                                                tooltipWidth: RegionDrawer.handTooltipWidth)

        regions.append(rectCard)
        regions.append(rectTooltip)

        if hasAttachedCard {
            let rectAttachedCard = drawCardRegion(offsetX: offsetX + 0.19, offsetY: offsetY + 0.015,
                                                  cardHeight: RegionDrawer.trinketHeight,
                                                  aspectRatio: RegionDrawer.trinketAspectRatio)
            regions.append(rectAttachedCard)
        }

        return regions
    }

    func drawBgHeroTrinketRegions(isPlayerBoard: Bool, hasAttachedCard: Bool, tooltipHeight: Double) -> [CGRect] {
        let baseOffsetX = 0.383
        let baseOffsetY = isPlayerBoard ? 0.48 : 0.0
        var regions = [CGRect]()

        let offsetX = baseOffsetX
        let offsetY = isPlayerBoard ? baseOffsetY : baseOffsetY - 0.03

        let rectCard = drawCardRegion(offsetX: offsetX, offsetY: offsetY,
                                      cardHeight: RegionDrawer.trinketHeight,
                                      aspectRatio: RegionDrawer.trinketAspectRatio)
        let tooltipOffsetX = offsetX - RegionDrawer.trinketToToolTipOffsetX + 0.027
        let rectTooltip = drawCardTooltipRegion(offsetX: tooltipOffsetX, offsetY: offsetY + 0.008,
                                                height: tooltipHeight * 1.08,
                                                tooltipWidth: RegionDrawer.handTooltipWidth)

        regions.append(rectCard)
        regions.append(rectTooltip)

        if hasAttachedCard {
            let rectAttachedCard = drawCardRegion(offsetX: offsetX + 0.19, offsetY: offsetY + 0.015,
                                                  cardHeight: RegionDrawer.trinketHeight,
                                                  aspectRatio: RegionDrawer.trinketAspectRatio)
            regions.append(rectAttachedCard)
        }

        return regions
    }

    func drawBgHeroPickingTooltipRegion(zoneSize: Int, zonePosition: Int, tooltipOnRight: Bool,
                                        numCards: Int, buddiesEnabled: Bool = false) -> [CGRect] {
        var regions = [CGRect]()

        // At this time we're only confident about the layout if the zone contains exactly 4 targets
        // (as is the case for Battlegrounds Hero Picking)
        if zoneSize != 4 {
            return regions
        }

        let totalWidth = Double(zoneSize) * RegionDrawer.bgHeroPickHeroWidth
            + Double(zoneSize - 1) * RegionDrawer.bgHeroPickHeroXSpacing
        let leftEdge = 0.50 - totalWidth / 2 // 0.065

        let zoneIndex = max(zonePosition - 1, 0)
        let heroX = leftEdge + Double(zoneIndex)
            * (RegionDrawer.bgHeroPickHeroWidth + RegionDrawer.bgHeroPickHeroXSpacing) // * 0.2365
        let heroY = 0.29

        let offsetX = heroX + (tooltipOnRight ? 0.135 : -0.16)
        let offsetY = heroY - 0.075

        let rectCard = drawHeroPowerRegion(offsetX: offsetX, offsetY: offsetY,
                                           heroPowerHeight: RegionDrawer.bgsHeroPowerHeight,
                                           heroAspectRatio: RegionDrawer.bgsHeroPowerAspectRatio)
        regions.append(rectCard)

        if buddiesEnabled {
            let extraOffset = tooltipOnRight ? 0.05 : -0.05
            let rectBuddy = drawCardRegion(
                offsetX: offsetX + extraOffset + (tooltipOnRight ? rectCard.width : -rectCard.width),
                offsetY: offsetY)
            regions.append(rectBuddy)
        }

        return regions
    }

    func drawMulliganAnomalyRegions(hasAttachedCard: Bool, isTooltip: Bool) -> [CGRect] {
        let offsetX = 0.383
        let offsetY = 0.16
        var regions = [CGRect]()
        regions.append(drawCardRegion(offsetX: offsetX, offsetY: offsetY,
                                      cardHeight: RegionDrawer.anomalyHeight,
                                      aspectRatio: RegionDrawer.anomalyAspectRatio))
        if hasAttachedCard {
            regions.append(drawCardRegion(offsetX: offsetX + 0.293, offsetY: offsetY,
                                          cardHeight: RegionDrawer.anomalyHeight,
                                          aspectRatio: RegionDrawer.anomalyAspectRatio))
        }
        return regions
    }

    func drawDiscoverCardRegions(zoneSize: Int, hasDarkGifts: Bool) -> [CGRect] {
        var regions = [CGRect]()

        if zoneSize == 0 {
            return regions
        }

        let cardSpacing = hasDarkGifts ? RegionDrawer.darkGiftCardSpacing : 0.27
        let layoutCenter = hasDarkGifts ? 0.519 : 0.53
        let cardY = hasDarkGifts ? RegionDrawer.darkGiftCardY : 0.29

        let totalWidth = Double(zoneSize) * cardSpacing
        let leftEdge = layoutCenter - totalWidth / 2

        for i in 0 ..< zoneSize {
            let cardX = leftEdge + Double(i) * cardSpacing
            let rect = hasDarkGifts
                ? drawCardRegion(offsetX: cardX, offsetY: cardY,
                                 cardHeight: RegionDrawer.darkGiftCardHeight,
                                 aspectRatio: RegionDrawer.darkGiftCardAspectRatio)
                : drawCardRegion(offsetX: cardX, offsetY: cardY)
            regions.append(rect)
        }

        return regions
    }

    func drawTrinketPickingRegions(zoneSize: Int) -> [CGRect] {
        if zoneSize == 0 {
            return [CGRect]()
        }

        let trinketPickCardSpacing = 0.192
        let cardY = 0.32
        let cardHeight = 0.320

        let totalWidth = Double(zoneSize) * trinketPickCardSpacing
        let leftEdge = 0.51 - totalWidth / 2

        let firstCard = drawCardRegion(offsetX: leftEdge, offsetY: cardY, cardHeight: cardHeight,
                                       aspectRatio: RegionDrawer.trinketAspectRatio)
        let lastCard = drawCardRegion(offsetX: leftEdge + Double(zoneSize - 1) * trinketPickCardSpacing,
                                      offsetY: cardY, cardHeight: cardHeight,
                                      aspectRatio: RegionDrawer.trinketAspectRatio)

        let x = firstCard.origin.x
        let right = lastCard.origin.x + lastCard.width
        let block = CGRect(x: x, y: firstCard.origin.y, width: right - x, height: firstCard.height)

        return [block]
    }
}
