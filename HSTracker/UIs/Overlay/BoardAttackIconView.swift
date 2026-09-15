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

    init(isPlayer: Bool) {
        self.isPlayer = isPlayer
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
    // The overlay's real, post-scale size. Like the turn timers, the icons
    // belong in RootOverlayView's fixed-pixel layer and not its 1080-reference
    // scaled subtree: OverlayWindow.UpdateScaling gives them no ScaleTransform,
    // so HDT draws the Grid at a flat 75x75 however large the client is.
    let canvasSize: CGSize

    // Width / Height on the Grid.
    private static let size: CGFloat = 75

    // Config.AttackIconPlayerVerticalPosition / HorizontalPosition and the
    // opponent's pair - the numbers SizeHelper.playerBoardDamageFrame and
    // opponentBoardDamageFrame used to hold.
    private static let playerVertical: CGFloat = 67.62
    private static let playerHorizontal: CGFloat = 25.5
    private static let opponentVertical: CGFloat = 22.39
    private static let opponentHorizontal: CGFloat = 25.5

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
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
    }

    private var icon: some View {
        ZStack {
            Image("board_damage")
                .resizable()
                .frame(width: Self.size, height: Self.size)
            // The block sets Width, Height and TextAlignment, so
            // OutlinedTextBlock.OnRender centres the line in its own 75pt height
            // and then drops it by a twentieth of a line. The Margin's 3pt lands
            // on top of that, less the 1.5pt WPF takes back re-centring a 75pt
            // child in the 72pt the margin leaves it.
            Text(verbatim: viewModel.text)
                .chunkFive(size: Self.fontSize)
                .outlinedText()
                .fixedSize()
                .frame(width: Self.size, height: Self.size)
                .offset(y: Self.textMargin / 2 + Self.lineHeight * 0.05)
        }
        .frame(width: Self.size, height: Self.size)
    }

    // Canvas.SetLeft(icon, Helper.GetScaledXPos(horizontal / 100, Width, ScreenRatio)).
    private var originX: CGFloat {
        let horizontal = viewModel.isPlayer ? Self.playerHorizontal : Self.opponentHorizontal
        let ratio = (4.0 / 3.0) / (canvasSize.width / canvasSize.height)
        return SizeHelper.getScaledXPos(horizontal / 100.0, width: canvasSize.width, ratio: ratio)
    }

    // Canvas.SetTop(icon, Height * vertical / 100).
    private var originY: CGFloat {
        let vertical = viewModel.isPlayer ? Self.playerVertical : Self.opponentVertical
        return canvasSize.height * vertical / 100.0
    }

    private static let lineHeight: CGFloat = {
        guard let font = NSFont(name: "ChunkFive", size: BoardAttackIconView.fontSize) else {
            return BoardAttackIconView.fontSize
        }
        return font.ascender - font.descender + font.leading
    }()
}

@available(macOS 10.15, *)
#Preview {
    let vm = BoardAttackIconViewModel(isPlayer: true)
    vm.isShown = true
    vm.update(damage: 14, hasInfiniteDamage: false)
    return BoardAttackIconView(viewModel: vm, canvasSize: CGSize(width: 1440, height: 1080))
        .frame(width: 1440, height: 1080)
        .background(Color.gray)
}
