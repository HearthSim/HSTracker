//
//  TrackerPanelView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// One of the two deck trackers on the overlay canvas.
///
/// HDT wraps each stack in a `Border` of a fixed height and puts the stack itself
/// inside it (`Windows/OverlayWindow.xaml`):
///
///   <Border Name="BorderStackPanelPlayer" Height="{Binding PlayerStackHeight}">
///     <StackPanel Name="StackPanelPlayer" Width="218"
///                 VerticalAlignment="{Binding PlayerStackPanelAlignment}"
///                 utility:CardListHelper.AutoScaleCardTiles="True"> ... </StackPanel>
///   </Border>
///
/// with `PlayerStackHeight = (PlayerDeckHeight / 100 * Height) / (OverlayPlayerScaling / 100)`,
/// the border placed from `PlayerDeckTop` / `PlayerDeckLeft` and the stack given
/// `OverlayPlayerScaling` as a `ScaleTransform`. All of that is reproduced below;
/// `AutoScaleCardTiles` - shrinking the card rows until the stack fits its box -
/// is `TrackerPanelLayout`.
@available(macOS 10.15, *)
struct TrackerPanelView: View {
    @ObservedObject var viewModel: TrackerPanelViewModel
    /// The canvas's real, post-scale size - the same Width/Height HDT's
    /// percentages are taken against.
    let canvasSize: CGSize
    /// `Settings.windowsLocked`, HDT's `_uiMovable` inverted.
    let isLocked: Bool
    /// The hover/tooltip handler the hosted `CardBar`s report through. Observed
    /// because the synergy highlight it publishes has to reach the card lists.
    @ObservedObject var hoverHandler: TrackerCardHoverHandler

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                panel
                // HDT gives every movable element a #4C0000FF box while the
                // overlay is unlocked (OverlayWindow.Input.cs UnlockUi), which is
                // both the drag handle and the ResizeGrip's corner.
                if !isLocked {
                    movableBox
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .preference(key: InteractiveRegionPreferenceKey.self, value: interactiveRegions)
        .preference(key: HoverRegionPreferenceKey.self, value: hoverRegions)
    }

    /// Where the cursor being on the panel matters without a click ever being
    /// claimed - HDT's `IsOverlayHoverVisible`. Two of those here: the whole
    /// opponent stack, which the link-opponent-deck prompt follows the cursor
    /// onto (`StackPanelOpponent`'s MouseEnter/MouseLeave), and the graveyard
    /// counter, which opens its minion list.
    ///
    /// Both rects are worked out from the layout rather than read off a
    /// GeometryReader under the panel: `.offset` and `.scaleEffect` are paint
    /// transforms that leave the layout alone, so a reader beneath them reports
    /// the untransformed position and unscaled size.
    private var hoverRegions: [HoverRegion] {
        guard viewModel.isShown else { return [] }
        let layout = self.layout
        guard layout.width > 0, layout.boxHeight > 0 else { return [] }
        let width = layout.width * scale

        var regions = [HoverRegion]()
        if viewModel.playerType == .opponent {
            regions.append(HoverRegion(id: TrackerPanelViewModel.opponentStackHoverRegionID,
                                       rect: CGRect(x: originX, y: originY,
                                                    width: width, height: layout.boxHeight * scale)))
        }
        if viewModel.graveyardDetails,
           let counter = layout.offset(of: .deckPanel(.graveyard), centered: viewModel.isCentered) {
            regions.append(HoverRegion(id: viewModel.graveyardHoverRegionID,
                                       rect: CGRect(x: originX,
                                                    y: originY + counter.y * scale,
                                                    width: width,
                                                    height: counter.height * scale)))
        }
        return regions
    }

    private var layout: TrackerPanelLayout {
        TrackerPanelLayout(viewModel: viewModel, canvasHeight: canvasSize.height)
    }

    private var scale: CGFloat { CGFloat(viewModel.scaling) / 100.0 }

    // Canvas.SetLeft / Canvas.SetTop, in the canvas's real pixels. The player
    // stack hangs its right edge on PlayerDeckLeft - HDT subtracts the scaled
    // width there and does not for the opponent (OverlayWindow.Update.cs
    // UpdateElementPositions).
    private var originX: CGFloat {
        let base = canvasSize.width * CGFloat(viewModel.left) / 100.0
        return viewModel.playerType == .opponent ? base : base - layout.width * scale
    }
    private var originY: CGFloat { canvasSize.height * CGFloat(viewModel.top) / 100.0 }

    /// The panel only stops being click-through while the overlay is unlocked,
    /// which is exactly what the tracker's own window did: `OverWindowController`
    /// set `ignoresMouseEvents = Settings.windowsLocked` every time the window was
    /// shown, so a locked tracker passed clicks *and* hovers straight through to
    /// Hearthstone. Keeping that rule means the drag and the resize grip work
    /// while the overlay is unlocked, and the overlay stays click-through over the
    /// trackers the rest of the time.
    private var interactiveRegions: [CGRect] {
        guard viewModel.isShown, !isLocked else { return [] }
        let box = layout.boxHeight * scale
        guard layout.width > 0, box > 0 else { return [] }
        return [CGRect(x: originX, y: originY, width: layout.width * scale, height: box)]
    }

    private var panel: some View {
        let layout = self.layout
        return VStack(spacing: 0) {
            ForEach(layout.sections, id: \.kind) { section in
                sectionView(section, layout: layout)
                    .frame(width: layout.width, height: section.height)
            }
        }
        .frame(width: layout.width, height: layout.boxHeight,
               alignment: viewModel.isCentered ? .center : .top)
        // The black backdrop the tracker's own window drew behind the stack -
        // Settings.trackerOpacity was that window's background alpha
        // (OverWindowController/Tracker.setOpacity). HDT has no equivalent, but
        // the setting is one HSTracker has always had, so it carries over as the
        // panel's own background rather than the window's.
        .background(Color.black.opacity(Settings.trackerOpacity / 100.0))
        .opacity(viewModel.opacity / 100.0)
        // anchor: .topLeading so the panel's corner stays on the offset origin,
        // which is what the interactive region above assumes.
        .scaleEffect(scale, anchor: .topLeading)
        .offset(x: originX, y: originY)
    }

    /// The drag and resize surface, laid over the panel in the canvas's own,
    /// post-scale pixels - a sibling of the panel rather than an overlay inside
    /// it, because a gesture attached under the `.scaleEffect` would report its
    /// translation in the panel's pre-scale space and the percentages below are
    /// taken against the canvas.
    ///
    /// HDT does the same: `_movableElements[BorderStackPanelPlayer]` is a
    /// separate `ResizeGrip` on its canvas, sized to the scaled stack.
    private var movableBox: some View {
        let box = layout.boxHeight * scale
        let width = layout.width * scale
        return ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color(hex: "#4C0000FF"))
                .frame(width: width, height: box)
                .gesture(dragGesture)
            // The bottom-right corner, which HDT treats as the resize grip: a
            // mouse-down within 30pt of it resizes instead of moving.
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: TrackerPanelLayout.resizeGripSize,
                       height: TrackerPanelLayout.resizeGripSize)
                .gesture(resizeGesture)
        }
        .frame(width: width, height: box, alignment: .bottomTrailing)
        .offset(x: originX, y: originY)
    }

    // HDT only moves overlay elements while the overlay is unlocked (_uiMovable,
    // toggled from the same place HSTracker toggles Settings.windowsLocked), and
    // saves the config on mouse up.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard !isLocked else { return }
                viewModel.drag(translation: value.translation, canvasSize: canvasSize)
            }
            .onEnded { _ in viewModel.endDrag() }
    }

    /// The grip only ever changes the height, and HDT clamps it at 5% of the
    /// client (`OverlayWindow.Input.cs`).
    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { viewModel.resize(translation: $0.translation, canvasSize: canvasSize) }
            .onEnded { _ in viewModel.endDrag() }
    }

    // MARK: - Sections

    @ViewBuilder
    private func sectionView(_ section: TrackerPanelLayout.Section, layout: TrackerPanelLayout) -> some View {
        switch section.kind {
        case .deckPanel(.deckTitle):
            TrackerHeroBarView(heroCardId: viewModel.playerClassId,
                               name: viewModel.playerName,
                               // The AppKit tracker drew the opponent's hero bar
                               // costless and the player's with its gem.
                               hidesCost: viewModel.playerType == .opponent)
        case .deckPanel(.wins):
            TrackerTextFrameView(make: { StringTracker() },
                                 configure: { $0.message = viewModel.recordMessage })
        case .deckPanel(.cards):
            TrackerCardListView(content: viewModel.cards,
                                playerType: viewModel.playerType,
                                cardHeight: layout.cardHeight,
                                delegate: hoverHandler,
                                highlight: hoverHandler.deckHighlight,
                                highlightVersion: hoverHandler.highlightVersion)
        case .deckPanel(.cardsTop):
            lens(viewModel.topCards, label: String.localizedString("On Top", comment: ""), layout: layout)
        case .deckPanel(.cardsBottom):
            lens(viewModel.bottomCards, label: String.localizedString("On Bottom", comment: ""), layout: layout)
        case .deckPanel(.sideboards):
            TrackerSideboardsView(sideboards: viewModel.sideboards,
                                  version: viewModel.sideboardsVersion,
                                  reset: viewModel.sideboardsReset,
                                  playerType: viewModel.playerType,
                                  cardHeight: layout.cardHeight,
                                  frameHeight: layout.smallFrameHeight,
                                  delegate: hoverHandler)
        case .deckPanel(.cardCounter):
            TrackerTextFrameView(make: { CardCounter() }, configure: {
                $0.handCount = viewModel.handCount
                $0.deckCount = viewModel.deckCount
            })
        case .deckPanel(.drawChances):
            if viewModel.playerType == .opponent {
                TrackerTextFrameView(make: { OpponentDrawChance() }, configure: {
                    $0.drawChance1 = viewModel.drawChance1
                    $0.drawChance2 = viewModel.drawChance2
                    $0.handChance1 = viewModel.opponentHandChance1
                    $0.handChance2 = viewModel.opponentHandChance2
                })
            } else {
                TrackerTextFrameView(make: { PlayerDrawChance() }, configure: {
                    $0.drawChance1 = viewModel.drawChance1
                    $0.drawChance2 = viewModel.drawChance2
                })
            }
        case .deckPanel(.graveyard):
            graveyardCounter(layout: layout)
        case .packageLens:
            // OverlayWindow.xaml draws this lens with the Arenasmith mark in
            // premium gold; its label carries the package's key card.
            TrackerDeckLensView(content: viewModel.packageCards,
                                label: viewModel.packageLabel,
                                icon: .arenasmith,
                                isPremium: true,
                                playerType: viewModel.playerType,
                                cardHeight: layout.cardHeight,
                                frameHeight: layout.smallFrameHeight,
                                delegate: hoverHandler)
        case .relatedLens:
            lens(viewModel.relatedCards,
                 label: String.localizedString("Related_Cards", comment: ""),
                 layout: layout)
        }
    }

    private func lens(_ content: TrackerCardListContent, label: String, layout: TrackerPanelLayout) -> some View {
        TrackerDeckLensView(content: content,
                            label: label,
                            icon: .lens,
                            isPremium: false,
                            playerType: viewModel.playerType,
                            cardHeight: layout.cardHeight,
                            frameHeight: layout.smallFrameHeight,
                            delegate: hoverHandler,
                            highlight: hoverHandler.deckHighlight,
                            highlightVersion: hoverHandler.highlightVersion)
    }

    /// The counter itself is the theme's graveyard frame; the card list it opens
    /// on hover is a sibling on the canvas - see `TrackerGraveyardDetailsView`,
    /// driven by the hover region reported above.
    private func graveyardCounter(layout: TrackerPanelLayout) -> some View {
        TrackerTextFrameView(make: { GraveyardCounter() }, configure: {
            $0.minions = viewModel.graveyardMinionCount
            $0.murlocks = viewModel.graveyardMurlocCount
        })
    }
}

/// The card-row shrinking HDT gets from `CardListHelper.AutoScaleCardTiles`, and
/// with it every section's height - the port of what `Tracker.updateFrames` did
/// by hand.
///
/// Everything here is in the stack's own, pre-`ScaleTransform` units, the way
/// HDT's `PlayerStackHeight` is: the scale is applied once to the finished panel.
@available(macOS 10.15, *)
struct TrackerPanelLayout {
    /// How close to the bottom-right corner a mouse-down counts as the resize
    /// grip in HDT (`OverlayWindow.Input.cs`).
    static let resizeGripSize: CGFloat = 30

    enum Kind: Hashable {
        case deckPanel(DeckPanel)
        case packageLens
        case relatedLens
    }

    struct Section {
        let kind: Kind
        let height: CGFloat
    }

    let width: CGFloat
    let cardHeight: CGFloat
    let smallFrameHeight: CGFloat
    let bigFrameHeight: CGFloat
    let boxHeight: CGFloat
    let sections: [Section]

    /// Where a section sits inside the box, in the stack's own units - the sum of
    /// what precedes it, plus the inset a centred stack starts at.
    func offset(of kind: Kind, centered: Bool) -> (y: CGFloat, height: CGFloat)? {
        let content = sections.reduce(0) { $0 + $1.height }
        var y = centered ? max((boxHeight - content) / 2, 0) : 0
        for section in sections {
            if section.kind == kind {
                return (y, section.height)
            }
            y += section.height
        }
        return nil
    }

    init(viewModel: TrackerPanelViewModel, canvasHeight: CGFloat) {
        let isOpponent = viewModel.playerType == .opponent

        width = SizeHelper.trackerWidth

        // HSTracker's card size is the row height the tracker is authored at, and
        // every frame PNG is drawn at 217x40 (or x71) divided by the same ratio -
        // see TextFrame.ratio. HDT has no equivalent; its rows are always 34 and
        // only OverlayPlayerScaling resizes the stack. Keeping it means the
        // scaling setting multiplies the chosen size rather than replacing it.
        let ratio: CGFloat
        let baseCardHeight: CGFloat
        switch Settings.cardSize {
        case .tiny: ratio = CGFloat(kRowHeight / kTinyRowHeight); baseCardHeight = CGFloat(kTinyRowHeight)
        case .small: ratio = CGFloat(kRowHeight / kSmallRowHeight); baseCardHeight = CGFloat(kSmallRowHeight)
        case .medium: ratio = CGFloat(kRowHeight / kMediumRowHeight); baseCardHeight = CGFloat(kMediumRowHeight)
        case .huge: ratio = CGFloat(kRowHeight / kHighRowHeight); baseCardHeight = CGFloat(kHighRowHeight)
        case .big: ratio = 1.0; baseCardHeight = CGFloat(kRowHeight)
        }
        smallFrameHeight = (40 / ratio).rounded()
        bigFrameHeight = (71 / ratio).rounded()

        // PlayerStackHeight: the box the stack has to fit into, in its own units.
        let scale = max(CGFloat(viewModel.scaling) / 100.0, 0.01)
        boxHeight = max(canvasHeight * CGFloat(viewModel.height) / 100.0 / scale, 0)

        // Which sections are up, in the configured order, and how tall the fixed
        // ones are. The two lenses HDT appends after the ordered list -
        // OpponentPackageCardsDeckLens then OpponentRelatedCardsDeckLens
        // (OverlayWindow.UpdateOpponentLayout) - are appended here too.
        let lensChrome = smallFrameHeight + 5
        var kinds: [(Kind, cards: Int, fixed: CGFloat)] = []
        for panel in viewModel.panelOrder {
            switch panel {
            case .deckTitle:
                let shown = isOpponent
                    ? Settings.showOpponentClassInTracker && viewModel.playerClassId != nil
                    : Settings.showDeckNameInTracker
                if shown { kinds.append((.deckPanel(panel), 0, smallFrameHeight)) }
            case .wins:
                if !isOpponent && Settings.showWinLossRatio {
                    kinds.append((.deckPanel(panel), 0, smallFrameHeight))
                }
            case .cards:
                kinds.append((.deckPanel(panel), viewModel.cards.cards.count, 0))
            case .cardsTop:
                if !isOpponent && Settings.showPlayerCardsTop && !viewModel.topCards.cards.isEmpty {
                    kinds.append((.deckPanel(panel), viewModel.topCards.cards.count, lensChrome))
                }
            case .cardsBottom:
                if !isOpponent && Settings.showPlayerCardsBottom && !viewModel.bottomCards.cards.isEmpty {
                    kinds.append((.deckPanel(panel), viewModel.bottomCards.cards.count, lensChrome))
                }
            case .sideboards:
                if !isOpponent && !Settings.hidePlayerSideboards && viewModel.sideboardCardCount > 0 {
                    kinds.append((.deckPanel(panel), viewModel.sideboardCardCount,
                                  smallFrameHeight * CGFloat(viewModel.sideboardBoxCount)))
                }
            case .cardCounter:
                let shown = isOpponent ? Settings.showOpponentCardCount : Settings.showPlayerCardCount
                if shown { kinds.append((.deckPanel(panel), 0, smallFrameHeight)) }
            case .drawChances:
                let shown = isOpponent ? Settings.showOpponentDrawChance : Settings.showPlayerDrawChance
                if shown {
                    kinds.append((.deckPanel(panel), 0, isOpponent ? bigFrameHeight : smallFrameHeight))
                }
            case .graveyard:
                if viewModel.showGraveyard { kinds.append((.deckPanel(panel), 0, smallFrameHeight)) }
            }
        }
        if isOpponent {
            if !Settings.hideOpponentArenaPackages && !viewModel.packageCards.cards.isEmpty {
                kinds.append((.packageLens, viewModel.packageCards.cards.count, lensChrome))
            }
            if Settings.showOpponentRelatedCards && !viewModel.relatedCards.cards.isEmpty {
                kinds.append((.relatedLens, viewModel.relatedCards.cards.count, lensChrome))
            }
        }

        let fixedHeight = kinds.reduce(0) { $0 + $1.fixed }
        let totalCards = kinds.reduce(0) { $0 + $1.cards }
        if totalCards > 0 {
            cardHeight = min(baseCardHeight, max((boxHeight - fixedHeight) / CGFloat(totalCards), 0))
        } else {
            cardHeight = baseCardHeight
        }

        let rowHeight = cardHeight
        sections = kinds.map { Section(kind: $0.0, height: $0.fixed + CGFloat($0.cards) * rowHeight) }
    }
}
