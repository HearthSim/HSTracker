//
//  OverlayWidgetPlacement.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// Where one of the overlay canvas's movable widgets sits - a side's counters,
/// its active effects, its board attack icon or its max-resources widget, and
/// the three turn timers - and what dragging it does.
///
/// HDT registers each of these with `_movableElements`
/// (`OverlayWindow.Initialize.cs`) and drags them from its own mouse hook: a move
/// adds the cursor delta to the numbers in `Config`, and `MouseInputOnLmbUp`
/// saves them (`OverlayWindow.Input.cs`). Those numbers are percentages of the
/// client, so a placement survives a resolution change - which is why nothing
/// here is an absolute frame. The one exception is the timers' spacing, which HDT
/// keeps in points so the gap between the three stays as it was set.
@available(macOS 10.15, *)
final class OverlayWidgetPlacement: ObservableObject {
    /// Which pair of `Config` numbers this reads and writes, and - since HDT
    /// hand-writes the arithmetic per element in `OverlayWindow.Input.cs` - how
    /// a drag is converted into them.
    enum Widget {
        case counters
        case activeEffects
        /// `IconBoardAttackPlayer` / `IconBoardAttackOpponent`.
        case attackIcon
        /// `PlayerResourcesWidget` / `OpponentResourcesWidget`.
        case maxResources
        /// `LblTurnTime`, whose position carries the other two timers with it.
        case timers
        /// `LblPlayerTurnTime`, which moves only itself and its opposite number:
        /// dragging it changes `TimersHorizontalSpacing` / `TimersVerticalSpacing`
        /// - how far the two per-player timers sit from the middle one, in points
        /// rather than percentages.
        case timerSpacing
    }

    let widget: Widget
    let isPlayer: Bool

    /// `Canvas.SetTop`'s percentage. Measured down from the top of the client for
    /// the player and *up from the bottom* for the opponent, whose widgets hang
    /// by their bottom edge so a second row grows upwards - which is also why a
    /// drag subtracts there instead of adding (`OpponentCountersVertical -= …`).
    @Published private(set) var vertical: Double
    /// `Canvas.SetLeft`'s percentage, before `Helper.GetScaledXPos` spreads it
    /// across the client's aspect ratio.
    @Published private(set) var horizontal: Double

    /// SwiftUI reports a running total where HDT's mouse hook reports the delta
    /// since the last move, so each step is taken against the previous
    /// translation - the same shape as `TrackerPanelViewModel.drag`.
    private var lastDragTranslation: CGSize?

    init(widget: Widget, isPlayer: Bool) {
        self.widget = widget
        self.isPlayer = isPlayer
        switch (widget, isPlayer) {
        case (.counters, true):
            vertical = Settings.playerCountersVertical
            horizontal = Settings.playerCountersHorizontal
        case (.counters, false):
            vertical = Settings.opponentCountersVertical
            horizontal = Settings.opponentCountersHorizontal
        case (.activeEffects, true):
            vertical = Settings.playerActiveEffectsVertical
            horizontal = Settings.playerActiveEffectsHorizontal
        case (.activeEffects, false):
            vertical = Settings.opponentActiveEffectsVertical
            horizontal = Settings.opponentActiveEffectsHorizontal
        case (.attackIcon, true):
            vertical = Settings.attackIconPlayerVertical
            horizontal = Settings.attackIconPlayerHorizontal
        case (.attackIcon, false):
            vertical = Settings.attackIconOpponentVertical
            horizontal = Settings.attackIconOpponentHorizontal
        case (.maxResources, true):
            vertical = Settings.playerMaxResourcesVertical
            horizontal = Settings.playerMaxResourcesHorizontal
        case (.maxResources, false):
            vertical = Settings.opponentMaxResourcesVertical
            horizontal = Settings.opponentMaxResourcesHorizontal
        case (.timers, _):
            vertical = Settings.timersVerticalPosition
            horizontal = Settings.timersHorizontalPosition
        case (.timerSpacing, _):
            vertical = Settings.timersVerticalSpacing
            horizontal = Settings.timersHorizontalSpacing
        }
    }

    /// `translation` is in the canvas's own real pixels - the widgets themselves
    /// are drawn in the 1080-tall reference space, so the gesture is read in
    /// `CoordinateSpace.rootOverlayCanvas` to keep this arithmetic in the space
    /// HDT's percentages are taken against.
    ///
    /// `ratio` is the `ScreenRatio` the horizontal position is spread by, since
    /// `Helper.GetScaledXPos` maps the percentage onto the 4:3 area inside the
    /// client rather than onto the client itself.
    func drag(translation: CGSize, canvasSize: CGSize, ratio: CGFloat) {
        guard canvasSize.width > 0, canvasSize.height > 0, ratio > 0 else { return }
        let previous = lastDragTranslation ?? .zero
        let dx = translation.width - previous.width
        let dy = translation.height - previous.height
        lastDragTranslation = translation

        switch widget {
        case .counters, .activeEffects:
            // The opponent's copies hang by their bottom edge, so HDT subtracts
            // there: `OpponentCountersVertical -= delta.Y / Height`.
            vertical += Double(dy / canvasSize.height) * 100.0 * (isPlayer ? 1.0 : -1.0)
            horizontal += Double(dx / (canvasSize.width * ratio)) * 100.0
        case .attackIcon, .maxResources:
            // Both sides hang by their top edge here, so neither sign flips.
            vertical += Double(dy / canvasSize.height) * 100.0
            horizontal += Double(dx / (canvasSize.width * ratio)) * 100.0
        case .timers:
            // The one element whose horizontal percentage is of the plain client
            // width: `TimersHorizontalPosition += delta.X / Width`, with no
            // ScreenRatio, because UpdateElementPositions places it with
            // `Width * TimersHorizontalPosition / 100` rather than GetScaledXPos.
            vertical += Double(dy / canvasSize.height) * 100.0
            horizontal += Double(dx / canvasSize.width) * 100.0
        case .timerSpacing:
            // Points, not percentages: `TimersVerticalSpacing += delta.Y / 100`,
            // and HDT's delta is the pixel delta pre-multiplied by 100.
            vertical += Double(dy)
            horizontal += Double(dx)
        }
    }

    /// `MouseInputOnLmbUp`, which saves the config once the drag finishes.
    func endDrag() {
        lastDragTranslation = nil
        switch (widget, isPlayer) {
        case (.counters, true):
            Settings.playerCountersVertical = vertical
            Settings.playerCountersHorizontal = horizontal
        case (.counters, false):
            Settings.opponentCountersVertical = vertical
            Settings.opponentCountersHorizontal = horizontal
        case (.activeEffects, true):
            Settings.playerActiveEffectsVertical = vertical
            Settings.playerActiveEffectsHorizontal = horizontal
        case (.activeEffects, false):
            Settings.opponentActiveEffectsVertical = vertical
            Settings.opponentActiveEffectsHorizontal = horizontal
        case (.attackIcon, true):
            Settings.attackIconPlayerVertical = vertical
            Settings.attackIconPlayerHorizontal = horizontal
        case (.attackIcon, false):
            Settings.attackIconOpponentVertical = vertical
            Settings.attackIconOpponentHorizontal = horizontal
        case (.maxResources, true):
            Settings.playerMaxResourcesVertical = vertical
            Settings.playerMaxResourcesHorizontal = horizontal
        case (.maxResources, false):
            Settings.opponentMaxResourcesVertical = vertical
            Settings.opponentMaxResourcesHorizontal = horizontal
        case (.timers, _):
            Settings.timersVerticalPosition = vertical
            Settings.timersHorizontalPosition = horizontal
        case (.timerSpacing, _):
            Settings.timersVerticalSpacing = vertical
            Settings.timersHorizontalSpacing = horizontal
        }
    }
}

/// A widget's laid-out size, for the ones that have no fixed one to hand the
/// movable box - the resources widget is as wide as the resources it is showing.
@available(macOS 10.15, *)
struct OverlayWidgetSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// The box HDT paints over a movable element while the overlay is unlocked
/// (`OverlayWindow.Input.cs` `UnlockUi`), which is what the drag is picked up
/// from. HDT also puts a `ResizeGrip` in its corner; neither of these two widgets
/// has a size of its own to grip - they are as big as the counters or tiles
/// currently up - so only the move carries over.
///
/// The frame is authored in the 1080-tall reference space the widgets are drawn
/// in, and `canvasScale` converts it for the interactive region, which
/// `RootOverlayWindow` matches against the cursor in the canvas's real pixels.
@available(macOS 10.15, *)
struct OverlayWidgetMovableBox: View {
    @ObservedObject var placement: OverlayWidgetPlacement
    /// The widget's laid-out frame, in the space it is drawn in.
    let frame: CGRect
    /// The canvas's real size, which the drag's percentages are taken against.
    let canvasSize: CGSize
    /// What `frame` has to be multiplied by to reach the canvas's real pixels:
    /// `height / 1080` for a widget in the resolution-scaled subtree, and 1 for
    /// one in the fixed-pixel layer beside it (the timers and the attack icons,
    /// which HDT never gives a ScaleTransform).
    var canvasScale: CGFloat = 1

    /// `Helper.GetScaledXPos`'s ratio - the 4:3 area's share of the client's
    /// width, which a horizontal drag is measured in.
    private var ratio: CGFloat {
        guard canvasSize.width > 0 else { return 1 }
        return (4.0 / 3.0) / (canvasSize.width / canvasSize.height)
    }

    var body: some View {
        Rectangle()
            // HDT's #4C0000FF, the same wash it puts over a movable deck stack.
            .fill(Color(hex: "#4C0000FF"))
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .rootOverlayCanvas)
                    .onChanged { value in
                        placement.drag(translation: value.translation,
                                       canvasSize: canvasSize, ratio: ratio)
                    }
                    .onEnded { _ in placement.endDrag() }
            )
            .preference(key: InteractiveRegionPreferenceKey.self, value: [interactiveRegion])
    }

    /// Worked out from the layout rather than read off a `GeometryReader` under
    /// the box: `.offset` and the subtree's own `.scaleEffect` are paint
    /// transforms that leave the layout alone, so a reader beneath them reports
    /// the untransformed position and unscaled size - the same reason
    /// `TrackerPanelView` computes its regions by hand.
    private var interactiveRegion: CGRect {
        CGRect(x: frame.minX * canvasScale, y: frame.minY * canvasScale,
               width: frame.width * canvasScale, height: frame.height * canvasScale)
    }
}
