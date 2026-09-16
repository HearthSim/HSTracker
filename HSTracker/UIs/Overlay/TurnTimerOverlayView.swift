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

    func tick(seconds: Int, playerSeconds: Int, opponentSeconds: Int) {
        self.seconds = seconds
        self.playerSeconds = playerSeconds
        self.opponentSeconds = opponentSeconds
    }
}

@available(macOS 10.15, *)
struct TurnTimerOverlayView: View {
    @ObservedObject var viewModel: TurnTimerOverlayViewModel
    // The overlay's real, post-scale size. These three labels belong in
    // RootOverlayView's fixed-pixel layer rather than its 1080-reference scaled
    // subtree: OverlayWindow.UpdateScaling never gives them a ScaleTransform,
    // so HDT draws them at a flat 28pt/20pt however large the client is - which
    // is also what the AppKit TimerHud did, with its fixed 160x115 frame.
    let canvasSize: CGSize

    // Config.TimersHorizontalPosition / TimersVerticalPosition, the percentages
    // of the client size UpdateElementPositions places the middle timer at.
    private static let horizontalPosition: CGFloat = 72
    private static let verticalPosition: CGFloat = 44.5
    // Config.TimersHorizontalSpacing / TimersVerticalSpacing: how far the two
    // per-player timers sit right of, and above/below, that middle one.
    private static let horizontalSpacing: CGFloat = 48
    private static let verticalSpacing: CGFloat = 42
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
                    .offset(x: left + Self.horizontalSpacing, y: top - Self.verticalSpacing)

                label(Self.format(viewModel.playerSeconds), size: Self.playerTimeFontSize, color: .white)
                    .offset(x: left + Self.horizontalSpacing, y: top + Self.verticalSpacing)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
    }

    // Canvas.SetLeft(LblTurnTime, Width * TimersHorizontalPosition / 100).
    private var left: CGFloat {
        canvasSize.width * Self.horizontalPosition / 100
    }

    // Canvas.SetTop(LblTurnTime, Height * TimersVerticalPosition / 100).
    private var top: CGFloat {
        canvasSize.height * Self.verticalPosition / 100
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
    return TurnTimerOverlayView(viewModel: vm, canvasSize: CGSize(width: 1440, height: 1080))
        .frame(width: 1440, height: 1080)
        .background(Color.gray)
}
