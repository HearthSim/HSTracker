//
//  BoardAttackIconView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// One of HDT's two board attack icons, IconBoardAttackPlayer and
// IconBoardAttackOpponent: a 75x75 Grid holding board_damage.png and a
// HearthstoneTextBlock, declared straight on the overlay canvas in
// Windows/OverlayWindow.xaml. This replaces the pair of 50x50 BoardDamage
// NSPanels.
@available(macOS 10.15, *)
final class BoardAttackIconViewModel: ObservableObject {
    // Which of the two icons this is - they are identical apart from the canvas
    // position each is given.
    let isPlayer: Bool

    // HDT's Visibility on the Grid, from OverlayWindow.UpdateIcons.
    @Published var isShown = false

    // BoardState.Player.Damage / .HasInfiniteDamage, the two values
    // UpdateIcons reads to build the label.
    @Published var damage = 0
    @Published var hasInfiniteDamage = false

    // Where the icon sits, and what dragging it while the overlay is unlocked
    // does - HDT registers both icons with _movableElements.
    let placement: OverlayWidgetPlacement

    init(isPlayer: Bool) {
        self.isPlayer = isPlayer
        placement = OverlayWidgetPlacement(widget: .attackIcon, isPlayer: isPlayer)
    }

    // board.Player.HasInfiniteDamage ? $" ∞ + {Damage}" : Damage.ToString()
    // - the leading space is HDT's, balancing the "+" against the icon's centre.
    var text: String {
        hasInfiniteDamage ? " \u{221e} + \(damage)" : "\(damage)"
    }

    func update(damage: Int, hasInfiniteDamage: Bool) {
        self.damage = damage
        self.hasInfiniteDamage = hasInfiniteDamage
    }
}

@available(macOS 10.15, *)
struct BoardAttackIconView: View {
    @ObservedObject var viewModel: BoardAttackIconViewModel
    // Observed as well as the view model: a drag moves the icon without the
    // damage it is showing changing.
    @ObservedObject var placement: OverlayWidgetPlacement
    // `Settings.windowsLocked`, HDT's `_uiMovable` inverted.
    let isLocked: Bool
    // The overlay's real, post-scale size. Like the turn timers, the icons
    // belong in RootOverlayView's fixed-pixel layer and not its 1080-reference
    // scaled subtree: OverlayWindow.UpdateScaling gives them no ScaleTransform,
    // so HDT draws the Grid at a flat 75x75 however large the client is.
    let canvasSize: CGSize

    // Width / Height on the Grid.
    private static let size: CGFloat = 75

    // FontSize on the HearthstoneTextBlock, and the Margin="0,3,0,0" that
    // pushes it down inside the Grid.
    private static let fontSize: CGFloat = 24
    private static let textMargin: CGFloat = 3

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while hidden, which is what replaces
        // the window show/hide.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                icon.offset(x: originX, y: originY)
                // HDT paints a box over every movable element while the overlay
                // is unlocked and drags it from there (OverlayWindow.Input.cs).
                // No canvasScale: these icons are drawn in the canvas's own
                // pixels, not the resolution-scaled subtree.
                if !isLocked {
                    OverlayWidgetMovableBox(
                        placement: placement,
                        frame: CGRect(x: originX, y: originY, width: Self.size, height: Self.size),
                        canvasSize: canvasSize)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
    }

    private var icon: some View {
        ZStack {
            Image("board_damage")
                .resizable()
                .frame(width: Self.size, height: Self.size)
            // Placed by its baseline, because what HDT centres is not the glyphs:
            // the block sets Width, Height and TextAlignment, so
            // OutlinedTextBlock.OnRender centres WPF's *character cell* in the
            // 75pt height and drops it by a twentieth of a cell, then draws the
            // glyphs a cell-ascent below that. The cell runs from the font's line
            // gap down to its descender - 1.2em of ChunkFive against 0.7em of
            // digits - so centring the glyphs instead, which is what handing
            // SwiftUI a 75pt frame does, leaves the number riding about three
            // points high of the icon's disc.
            Text(verbatim: viewModel.text)
                .chunkFive(size: Self.fontSize)
                .outlinedText()
                .fixedSize()
                .frame(width: Self.size, height: Self.size, alignment: .top)
                .offset(y: Self.baselineY - Self.ascent)
        }
        .frame(width: Self.size, height: Self.size)
    }

    /// Where HDT's baseline lands inside the 75pt grid:
    ///
    ///     originY = (ActualHeight - FormattedText.Height) / 2 + FormattedText.Height * 0.05
    ///
    /// with the geometry built at that point - `BuildGeometry(new Point(0, originY))`
    /// - so `originY` is the top of the cell and the baseline falls `cellAscent`
    /// below it. The Margin="0,3,0,0" adds the rest: a 75pt-high block in the
    /// 72pt the margin leaves it is re-centred by `OutlinedTextBlock`'s own
    /// `VerticalAlignment.Center`, which gives half of those 3pt back.
    private static var baselineY: CGFloat {
        textMargin / 2 + (size - cellHeight) / 2 + cellHeight * 0.05 + cellAscent
    }

    /// WPF's character cell - `GlyphTypeface.Height`, and so `FormattedText.Height`
    /// for a single line - and how far into it the baseline sits. The gap hangs
    /// above the ascent, which is what makes the cell's ascent larger than the
    /// font's own.
    private static var cellHeight: CGFloat { lineHeight }
    private static var cellAscent: CGFloat { font.ascender + font.leading }

    /// How far below a SwiftUI text layer's top edge its baseline falls, which is
    /// what the offset above is measured from - `CardTileTheme.ascent`.
    private static var ascent: CGFloat { font.ascender }

    private static let font = NSFont(name: "ChunkFive", size: BoardAttackIconView.fontSize)
        ?? .systemFont(ofSize: BoardAttackIconView.fontSize)

    // Canvas.SetLeft(icon, Helper.GetScaledXPos(horizontal / 100, Width, ScreenRatio)).
    private var originX: CGFloat {
        let ratio = (4.0 / 3.0) / (canvasSize.width / canvasSize.height)
        return SizeHelper.getScaledXPos(CGFloat(placement.horizontal) / 100.0,
                                        width: canvasSize.width, ratio: ratio)
    }

    // Canvas.SetTop(icon, Height * vertical / 100).
    private var originY: CGFloat {
        canvasSize.height * CGFloat(placement.vertical) / 100.0
    }

    private static var lineHeight: CGFloat { font.ascender - font.descender + font.leading }
}

@available(macOS 10.15, *)
#Preview {
    let vm = BoardAttackIconViewModel(isPlayer: true)
    vm.isShown = true
    vm.update(damage: 14, hasInfiniteDamage: false)
    return BoardAttackIconView(viewModel: vm, placement: vm.placement, isLocked: true,
                               canvasSize: CGSize(width: 1440, height: 1080))
        .frame(width: 1440, height: 1080)
        .background(Color.gray)
}
