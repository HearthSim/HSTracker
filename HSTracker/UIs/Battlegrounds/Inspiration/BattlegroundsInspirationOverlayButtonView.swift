//
//  BattlegroundsInspirationOverlayButtonView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsInspirationOverlayButton: a 49x49 tab at the left
// end of BgsTopBar that re-opens the Inspiration panel once it has been used at
// least once this match.
//
// Border Width/Height 49, Margin="0,0,2,0", CornerRadius "0,0,3,3",
// BorderThickness "1,0,1,1" #141617, Background #23272a going to #343637 on
// hover, holding a 29x29 icon_inspiration inset by 10.
//
// HDT drives it off IsEnabled, animating opacity 0->1 and a -55 -> 0 Y
// translate on the way in (0.2s CubicEase) and back out over 0.3s after a 0.1s
// delay. IsEnabled is set to HasBeenActivated when the panel closes and false
// while it is open, which is exactly the condition below.
@available(macOS 10.15, *)
struct BattlegroundsInspirationOverlayButtonView: View {
    @ObservedObject var viewModel: BattlegroundsInspirationViewModel

    @SwiftUI.State private var isHovering = false

    private static let size: CGFloat = 49
    private static let hiddenOffset: CGFloat = -55

    private var isEnabled: Bool { viewModel.hasBeenActivated && !viewModel.isShown }

    var body: some View {
        Button {
            viewModel.show()
        } label: {
            Image("icon_inspiration")
                .resizable()
                .frame(width: 29, height: 29)
                .padding(10)
                .frame(width: Self.size, height: Self.size)
                .background(Color(hex: isHovering ? "#343637" : "#23272a"))
                .clipShape(BottomRoundedRect(radius: 3))
                .overlay(SidesAndBottomBorder(radius: 3).stroke(Color(hex: "#141617"), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .trackHover { isHovering = $0 }
        .frame(width: Self.size, height: Self.size)
        .padding(.trailing, 2)
        .opacity(isEnabled ? 1 : 0)
        .offset(y: isEnabled ? 0 : Self.hiddenOffset)
        .allowsHitTesting(isEnabled)
        // Only claims clicks while it is actually on screen; the collapsed
        // button sits behind the top bar where every click belongs to the game.
        .reportInteractiveRegion(when: isEnabled)
    }
}

// CornerRadius="0,0,3,3": square on top, rounded at both bottom corners.
@available(macOS 10.15, *)
private struct BottomRoundedRect: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// BorderThickness="1,0,1,1": left, right and bottom only - the top edge is open
// where the tab meets the screen edge.
@available(macOS 10.15, *)
private struct SidesAndBottomBorder: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let left = rect.minX + 0.5
        let right = rect.maxX - 0.5
        let bottom = rect.maxY - 0.5
        var path = Path()
        path.move(to: CGPoint(x: left, y: rect.minY))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: left + radius, y: bottom),
                          control: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: right - radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: right, y: bottom - radius),
                          control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: right, y: rect.minY))
        return path
    }
}
