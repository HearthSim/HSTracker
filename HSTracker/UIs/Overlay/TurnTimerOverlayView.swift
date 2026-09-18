//
//  TurnTimerOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's three turn timers - LblTurnTime, LblPlayerTurnTime and
// LblOpponentTurnTime - which are plain HearthstoneTextBlocks declared straight
// on the overlay canvas in Windows/OverlayWindow.xaml, not a window of their
// own. This replaces the single 160x115 TimerHud NSPanel that used to hold all
// three.
@available(macOS 10.15, *)
final class TurnTimerOverlayViewModel: ObservableObject {
    // HDT's Visibility on the three blocks, driven by ShowTimers/HideTimers.
    @Published var isShown = false

    // TimerState.Seconds, PlayerSeconds and OpponentSeconds, as
    // OverlayWindow.UpdateTurnTimer receives them.
    @Published var seconds = 0
    @Published var playerSeconds = 0
    @Published var opponentSeconds = 0

    // Where the three timers sit, and how far the two per-player ones sit from
    // the middle one. HDT registers LblTurnTime and LblPlayerTurnTime with
    // _movableElements separately: dragging the middle timer moves the group,
    // dragging the player's own changes only the spacing.
    let placement = OverlayWidgetPlacement(widget: .timers, isPlayer: true)
    let spacing = OverlayWidgetPlacement(widget: .timerSpacing, isPlayer: true)

    func tick(seconds: Int, playerSeconds: Int, opponentSeconds: Int) {
        self.seconds = seconds
        self.playerSeconds = playerSeconds
        self.opponentSeconds = opponentSeconds
    }
}

@available(macOS 10.15, *)
struct TurnTimerOverlayView: View {
    @ObservedObject var viewModel: TurnTimerOverlayViewModel
    // Observed as well as the view model: a drag moves the timers without the
    // seconds they are showing changing.
    @ObservedObject var placement: OverlayWidgetPlacement
    @ObservedObject var spacing: OverlayWidgetPlacement
    // `Settings.windowsLocked`, HDT's `_uiMovable` inverted.
    let isLocked: Bool
    // The overlay's real, post-scale size. These three labels belong in
    // RootOverlayView's fixed-pixel layer rather than its 1080-reference scaled
    // subtree: OverlayWindow.UpdateScaling never gives them a ScaleTransform,
    // so HDT draws them at a flat 28pt/20pt however large the client is - which
    // is also what the AppKit TimerHud did, with its fixed 160x115 frame.
    let canvasSize: CGSize

    // Config.TimersHorizontalSpacing / TimersVerticalSpacing: how far the two
    // per-player timers sit right of, and above/below, the middle one. Points
    // rather than percentages, as HDT keeps them, so the gap between the three
    // does not stretch with the client.
    private var horizontalSpacing: CGFloat { CGFloat(spacing.horizontal) }
    private var verticalSpacing: CGFloat { CGFloat(spacing.vertical) }
    // The extra -5 UpdateElementPositions gives the middle timer alone, so the
    // larger face still centres on the same line as the other two.
    private static let turnTimeVerticalAdjust: CGFloat = -5

    // FontSize on the three blocks in OverlayWindow.xaml.
    private static let turnTimeFontSize: CGFloat = 28
    private static let playerTimeFontSize: CGFloat = 20

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it, and rendering nothing while hidden - what the window
        // show/hide used to do.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                // LblTurnTime.Fill = Seconds < 0 ? LimeGreen : White. HSTracker's
                // TurnTimer clamps at zero rather than counting past the turn, so
                // the green state is carried over but never currently reached.
                label(Self.format(viewModel.seconds),
                      size: Self.turnTimeFontSize,
                      color: viewModel.seconds < 0 ? Color(red: 0.196, green: 0.804, blue: 0.196) : .white)
                    .offset(x: left, y: top + Self.turnTimeVerticalAdjust)

                label(Self.format(viewModel.opponentSeconds), size: Self.playerTimeFontSize, color: .white)
                    .offset(x: left + horizontalSpacing, y: top - verticalSpacing)

                label(Self.format(viewModel.playerSeconds), size: Self.playerTimeFontSize, color: .white)
                    .offset(x: left + horizontalSpacing, y: top + verticalSpacing)

                // HDT paints a box over every movable element while the overlay
                // is unlocked and drags it from there (OverlayWindow.Input.cs).
                // Two of them here, as HDT has: the middle timer carries all
                // three, and the player's own only changes the spacing - which
                // is why the pair moves and the middle one stays put.
                //
                // No canvasScale: the timers are drawn in the canvas's own
                // pixels, not the resolution-scaled subtree.
                if !isLocked {
                    OverlayWidgetMovableBox(
                        placement: placement,
                        frame: Self.labelFrame(x: left, y: top + Self.turnTimeVerticalAdjust,
                                               size: Self.turnTimeFontSize),
                        canvasSize: canvasSize)
                    OverlayWidgetMovableBox(
                        placement: spacing,
                        frame: Self.labelFrame(x: left + horizontalSpacing, y: top + verticalSpacing,
                                               size: Self.playerTimeFontSize),
                        canvasSize: canvasSize)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
    }

    /// The box HDT hands a movable element is that element's own laid-out size,
    /// which for these is one line of ChunkFive at the label's own size.
    private static func labelFrame(x: CGFloat, y: CGFloat, size: CGFloat) -> CGRect {
        let font = NSFont(name: "ChunkFive", size: size) ?? .systemFont(ofSize: size)
        let width = ("00:00" as NSString).size(withAttributes: [.font: font]).width
        return CGRect(x: x, y: y, width: ceil(width), height: ceil(lineHeight(size)))
    }

    // Canvas.SetLeft(LblTurnTime, Width * TimersHorizontalPosition / 100) - the
    // plain client width, with none of the ScreenRatio spreading the other
    // movable widgets' horizontal percentages go through.
    private var left: CGFloat {
        canvasSize.width * CGFloat(placement.horizontal) / 100
    }

    // Canvas.SetTop(LblTurnTime, Height * TimersVerticalPosition / 100).
    private var top: CGFloat {
        canvasSize.height * CGFloat(placement.vertical) / 100
    }

    // $"{seconds / 60 % 60:00}:{seconds % 60:00}" over Math.Abs(Seconds), and
    // "∞" for an infinite timer - which HSTracker's TurnTimer never
    // produces, so only the finite branch is reachable today.
    private static func format(_ seconds: Int) -> String {
        let seconds = abs(seconds)
        return String(format: "%02d:%02d", (seconds / 60) % 60, seconds % 60)
    }

    // A HearthstoneTextBlock with no Width, Height or TextAlignment set, so
    // OutlinedTextBlock.OnRender takes its unconstrained branch: the line is
    // drawn at the element's top, dropped by a twentieth of its own height.
    private func label(_ text: String, size: CGFloat, color: Color) -> some View {
        Text(verbatim: text)
            .chunkFive(size: size)
            .outlinedText(color)
            .fixedSize()
            .offset(y: Self.lineHeight(size) * 0.05)
    }

    private static func lineHeight(_ size: CGFloat) -> CGFloat {
        guard let font = NSFont(name: "ChunkFive", size: size) else { return size }
        return font.ascender - font.descender + font.leading
    }
}

@available(macOS 10.15, *)
#Preview {
    let vm = TurnTimerOverlayViewModel()
    vm.isShown = true
    vm.tick(seconds: 75, playerSeconds: 214, opponentSeconds: 187)
    return TurnTimerOverlayView(viewModel: vm, placement: vm.placement, spacing: vm.spacing,
                                isLocked: true, canvasSize: CGSize(width: 1440, height: 1080))
        .frame(width: 1440, height: 1080)
        .background(Color.gray)
}
