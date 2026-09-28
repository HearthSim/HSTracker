//
//  BoardOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// One hover target: the invisible Ellipse inside a BoardMinionOverlayView, or
// one of the ten rotated rectangles over the player's hand. HDT keeps these as
// real elements on its canvas and hit-tests the cursor against them with
// EllipseContains / RotatedRectContains; here the views report their geometry
// and BoardMouseOverDetection does the same tests against it.
struct BoardHoverTarget: Equatable {
    enum Kind: Equatable {
        case minion(isPlayer: Bool)
        case handCard
    }

    let kind: Kind
    let index: Int
    // The element's frame in the canvas's own pixels.
    let frame: CGRect
    // Rotation about the frame's centre, in degrees - HDT's RotateTransform on
    // the hand cards. Zero for the board ellipses.
    var angle: Double = 0

    // EllipseContains: the point normalised against the ellipse's radii.
    func containsAsEllipse(_ point: CGPoint) -> Bool {
        let radiusX = frame.width / 2
        let radiusY = frame.height / 2
        guard radiusX > 0, radiusY > 0 else { return false }
        let dx = point.x - frame.midX
        let dy = point.y - frame.midY
        return (dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1
    }

    // RotatedRectContains: the point rotated back about the rectangle's centre
    // and then tested against the unrotated frame.
    func containsAsRotatedRect(_ point: CGPoint) -> Bool {
        let radians = -angle * .pi / 180
        let dx = point.x - frame.midX
        let dy = point.y - frame.midY
        let rotated = CGPoint(x: frame.midX + dx * cos(radians) - dy * sin(radians),
                              y: frame.midY + dx * sin(radians) + dy * cos(radians))
        return rotated.x > frame.minX && rotated.x < frame.maxX
            && rotated.y > frame.minY && rotated.y < frame.maxY
    }
}

struct BoardHoverTargetsKey: PreferenceKey {
    static var defaultValue: [BoardHoverTarget] = []
    static func reduce(value: inout [BoardHoverTarget], nextValue: () -> [BoardHoverTarget]) {
        value.append(contentsOf: nextValue())
    }
}

// HDT's GridOpponentBoard and GridPlayerBoard: a row of seven
// BoardMinionOverlayViews per side, centred over Hearthstone's board. The
// ellipses in them are pure hover geometry and are never drawn; the only
// visible part is the Mercenaries ability strip.
//
// Belongs in RootOverlayView's fixed-pixel layer: OverlayWindow positions both
// grids with plain fractions of the client size and never gives either a
// ScaleTransform.
struct BoardOverlayView: View {
    @ObservedObject var viewModel: BoardOverlayViewModel
    let canvasSize: CGSize

    // OverlayWindow.BoardHeight and MinionWidth.
    static func boardHeight(_ canvasSize: CGSize) -> CGFloat { canvasSize.height * 0.158 }

    static func minionWidth(_ canvasSize: CGSize) -> CGFloat {
        canvasSize.width * 0.63 / 7 * ratio(canvasSize)
    }

    // OverlayWindow.MinionMargin, which is wider in Mercenaries because the
    // minions themselves are.
    static func minionMargin(_ canvasSize: CGSize, isMercenariesMatch: Bool) -> CGFloat {
        canvasSize.width * ratio(canvasSize) * (isMercenariesMatch ? 0.01 : 0.0029)
    }

    // BoardMinionOverlayViewModel.AbilitySize.
    static func abilitySize(_ canvasSize: CGSize) -> CGFloat { boardHeight(canvasSize) * 0.28 }

    static func ratio(_ canvasSize: CGSize) -> CGFloat {
        canvasSize.width > 0 ? (4.0 / 3.0) / (canvasSize.width / canvasSize.height) : 1
    }

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while hidden, which is what replaces
        // the window show/hide.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                row(isPlayer: false).offset(y: opponentTop)
                row(isPlayer: true).offset(y: playerTop)
                handTargets
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        // Purely a hover surface - it must never take a click away from
        // Hearthstone, so it reports no interactive region and nothing in it
        // opts into hit testing.
        .allowsHitTesting(false)
    }

    // A StackPanel Orientation="Horizontal" HorizontalAlignment="Center" of the
    // seven slots. Collapsed slots take no space, so the visible ones stay
    // centred however many there are.
    private func row(isPlayer: Bool) -> some View {
        let minions = viewModel.minions(isPlayer: isPlayer)
        return HStack(spacing: 0) {
            ForEach(0 ..< BoardOverlayViewModel.maxBoardSize, id: \.self) { index in
                if minions[index].isShown {
                    BoardMinionOverlayView(viewModel: minions[index],
                                           isPlayer: isPlayer,
                                           index: index,
                                           minionWidth: Self.minionWidth(canvasSize),
                                           boardHeight: Self.boardHeight(canvasSize),
                                           margin: Self.minionMargin(canvasSize,
                                                                     isMercenariesMatch: viewModel.isMercenariesMatch),
                                           abilitySize: Self.abilitySize(canvasSize))
                }
            }
        }
        .frame(width: canvasSize.width, height: Self.boardHeight(canvasSize))
    }

    private var opponentTop: CGFloat {
        Self.opponentTop(canvasSize, isMercenariesMatch: viewModel.isMercenariesMatch,
                         isMainAction: viewModel.isMainAction, mercsToNominate: viewModel.mercsToNominate)
    }

    private var playerTop: CGFloat {
        Self.playerTop(canvasSize, isMercenariesMatch: viewModel.isMercenariesMatch,
                       isMainAction: viewModel.isMainAction, mercsToNominate: viewModel.mercsToNominate)
    }

    // Canvas.SetTop(GridOpponentBoard, Height / 2 - BoardHeight - opponentBoardOffset).
    static func opponentTop(_ canvasSize: CGSize, isMercenariesMatch: Bool,
                            isMainAction: Bool, mercsToNominate: Bool) -> CGFloat {
        let offset = isMercenariesMatch && isMainAction && !mercsToNominate
            ? canvasSize.height * 0.142
            : canvasSize.height * 0.045
        return canvasSize.height / 2 - boardHeight(canvasSize) - offset
    }

    // Canvas.SetTop(GridPlayerBoard, Height / 2 - playerBoardOffset).
    static func playerTop(_ canvasSize: CGSize, isMercenariesMatch: Bool,
                          isMainAction: Bool, mercsToNominate: Bool) -> CGFloat {
        let offset: CGFloat
        if isMercenariesMatch {
            offset = isMainAction && !mercsToNominate
                ? canvasSize.height * -0.09
                : canvasSize.height * 0.003
        } else {
            offset = canvasSize.height * 0.03
        }
        return canvasSize.height / 2 - offset
    }

    // The ten rotated card rectangles over the player's hand. Nothing is drawn -
    // they exist only so a hovered card can be resolved to an entity, the same
    // job HDT's RectPlayerHand0..9 do.
    private var handTargets: some View {
        let count = min(viewModel.handCount, BoardOverlayViewModel.maxHandSize)
        return Color.clear.preference(
            key: BoardHoverTargetsKey.self,
            value: (0 ..< count).map { index in
                let pos = Self.handCardPosition(index: index, count: count, canvasSize: canvasSize)
                let width = canvasSize.height * 0.125
                let height = canvasSize.height * 0.189
                return BoardHoverTarget(
                    kind: .handCard,
                    index: index,
                    frame: CGRect(x: pos.x - width / 2, y: pos.y - height / 2,
                                  width: width, height: height),
                    angle: Self.handCardAngle(index: index, count: count, pos: pos,
                                              canvasSize: canvasSize))
            })
    }

    // OverlayWindow.CenterOfHand.
    static func centerOfHand(_ canvasSize: CGSize) -> CGPoint {
        CGPoint(x: canvasSize.width * 0.5 - canvasSize.height * 0.035,
                y: canvasSize.height * 0.95)
    }

    // OverlayWindow.GetCardSpacing.
    static func cardSpacing(count: Int, canvasSize: CGSize) -> CGFloat {
        let cardWidth = canvasSize.height / 10 * 1.27
        let maxHandWidth = canvasSize.width * ratio(canvasSize) * 0.36
        if CGFloat(count) * cardWidth > maxHandWidth {
            return maxHandWidth / CGFloat(count)
        }
        return cardWidth
    }

    // OverlayWindow.GetPlayerCardPosition: Hearthstone fans the hand, so the
    // cards bow upward from the centre and the outer ones sit lower.
    static func handCardPosition(index: Int, count: Int, canvasSize: CGSize) -> CGPoint {
        var cardWidth: CGFloat = 0
        var center: CGFloat = 0
        var setAngle: CGFloat = 0
        if count > 3 {
            setAngle = 1
            let width = 40 + CGFloat(count) * 2
            cardWidth = width / CGFloat(count)
            center = -width / 2
        }
        let rightOfCenter = cardWidth * CGFloat(index) + center
        var rightYOffset: CGFloat = 0
        let spacing = cardSpacing(count: count, canvasSize: canvasSize)
        if rightOfCenter > 0 {
            rightYOffset = sin(abs(rightOfCenter) * .pi / 180) * spacing / 2
        }
        let hand = centerOfHand(canvasSize)
        let x = hand.x - spacing / 2 * CGFloat(count - 1 - index * 2)
        var y: CGFloat = 1
        if count > 1 {
            y += pow(abs(CGFloat(index) - CGFloat(count / 2)), 2) / (4 * CGFloat(count)) * 0.11 * setAngle
                + rightYOffset * 0.0009
        }
        return CGPoint(x: x, y: y * hand.y)
    }

    // OverlayWindow.GetCardAngle.
    static func handCardAngle(index: Int, count: Int, pos: CGPoint, canvasSize: CGSize) -> Double {
        let extraRotation: CGFloat = count == 7 ? 0 : count > 4 ? CGFloat(count % 2) : 1
        let hand = centerOfHand(canvasSize)
        let direction = pos.x > hand.x
            ? -1 + (extraRotation * 0.3 * CGFloat(count - index) * max(1, CGFloat(index - 7)))
            : 1
        return Double((hand.y - pos.y) / canvasSize.height * 600 * direction
                      * (1 + sqrt(10.0 / CGFloat(index + 1)) * 0.08))
    }
}

// HDT's BoardMinionOverlayView: the hover ellipse, with the Mercenaries ability
// strip hanging off it.
struct BoardMinionOverlayView: View {
    @ObservedObject var viewModel: BoardMinionOverlayViewModel
    let isPlayer: Bool
    let index: Int
    let minionWidth: CGFloat
    let boardHeight: CGFloat
    let margin: CGFloat
    let abilitySize: CGFloat

    var body: some View {
        // The Grid: an Ellipse with horizontal margins, so the slot is the
        // minion's width plus a gap either side.
        Color.clear
            .frame(width: minionWidth, height: boardHeight)
            // Reports where the ellipse is. The ellipse has no Fill in HDT
            // either - it is measured, never painted. Measured *before* the
            // margins below, so the reported frame is the ellipse itself rather
            // than the slot around it; the Margin is on the Ellipse in HDT, so
            // it inflates the Grid and not the hover target.
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: BoardHoverTargetsKey.self,
                        value: [BoardHoverTarget(kind: .minion(isPlayer: isPlayer),
                                                 index: index,
                                                 frame: proxy.frame(in: .rootOverlayCanvas))]
                    )
                }
            )
            .padding(.horizontal, margin)
            // The ability strip sits in an IgnoreSizeDecorator, so it overflows
            // the slot without widening it.
            .overlay(abilityStrip, alignment: .top)
    }

    private var abilityStrip: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.abilities) { ability in
                MercenariesAbilityIconView(ability: ability, size: abilitySize)
                    .frame(width: abilitySize, height: abilitySize)
            }
        }
        .frame(width: abilitySize * CGFloat(viewModel.abilities.count), height: abilitySize)
        // AbilityPanelTopMargin, measured from the slot's top edge: above it for
        // the opponent, below the whole slot for the player.
        .offset(y: viewModel.abilityAlignment == .top
                ? -abilitySize - boardHeight * 0.12
                : boardHeight + boardHeight * 0.14)
        // AbilitiesVisibility is Hidden rather than Collapsed, so a strip that
        // steps aside for the hover tooltip leaves the others where they are.
        .opacity(viewModel.abilitiesVisible ? 1 : 0)
    }
}
