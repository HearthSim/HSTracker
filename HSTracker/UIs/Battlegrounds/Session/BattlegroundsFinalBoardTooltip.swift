//
//  BattlegroundsFinalBoardTooltip.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of the FinalBoardCanvas half of HDT's BattlegroundsGameView.xaml: the
// warband a past game ended on, shown while the cursor is over that game's row
// in the session panel's Latest Games list.
//
// HDT positions this with Canvas.Left/Top computed in
// BattlegroundsGameViewModel.OnMouseEnter and shrinks the whole thing with a
// ScaleTransform of .6; both are applied by the caller
// (BattlegroundsSessionView) since it is the one that knows where the hovered
// row sits.
@available(macOS 10.15, *)
struct BattlegroundsFinalBoardTooltip: View {
    let minions: [Entity]
    // Which side of the row the tooltip opens on, so the arrow can be drawn on
    // the edge that faces it (HDT's `tooltipToRight`).
    let tooltipToRight: Bool
    // The container's own unscaled width, which the arrow's position depends on
    // - HDT reads it as FinalBoardContainer.ActualWidth.
    let contentWidth: CGFloat

    // RenderTransform ScaleTransform ScaleX=".6" ScaleY=".6"
    static let scale: CGFloat = 0.6

    // Style TargetType="controls:BattlegroundsMinion": Width/Height 110,
    // Margin="0,15,-10,15". HSTracker's BattlegroundsMinionView composes its
    // art at 300x350 rather than HDT's square 256x256 viewbox, so the slot
    // keeps HDT's 110pt width and takes the height that preserves that aspect -
    // at a square 110x110 every minion renders visibly squashed.
    private static let minionWidth: CGFloat = 110
    private static let minionHeight: CGFloat = 110 * 350 / 300
    private static let minionOverlap: CGFloat = 10

    // FinalBoardCanvasTop, which shifts the box up far enough to stay centred
    // on the row it belongs to.
    static func canvasTop(minionCount: Int) -> CGFloat {
        minionCount > 0 ? -70 : -30
    }

    // FinalBoardCanvasLeft: to the right of the whole 240pt panel, or mirrored
    // to its left off the tooltip's own scaled width.
    static func canvasLeft(tooltipToRight: Bool, contentWidth: CGFloat) -> CGFloat {
        tooltipToRight ? 247 : (contentWidth * -0.6) - 10
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            container
            arrow
        }
    }

    private var container: some View {
        VStack(spacing: 0) {
            // Border BorderBrush="#4A5256" BorderThickness="0,0,0,1"
            // Background="#1C2022" CornerRadius="3 3 0 0", stretched to the
            // container's width.
            Text(String.localizedString("Battlegrounds_Session_Game_Tooltip_Final_Board", comment: ""))
                .font(.system(size: 18))
                .foregroundColor(Color.white.opacity(0.55))
                // Label, so Padding="5" from its default template.
                .padding(5)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#1C2022"))
                .overlay(Color(hex: "#4A5256").frame(height: 1), alignment: .bottom)

            // StackPanel Name="FinalBoard" Margin="0,0,10,0"
            HStack(spacing: -Self.minionOverlap) {
                if minions.isEmpty {
                    Text(String.localizedString("Battlegrounds_Session_Game_Tooltip_Final_Board_Empty", comment: ""))
                        .font(.system(size: 18))
                        .foregroundColor(Color.white.opacity(0.55))
                        // Margin="30,20,20,20" on top of the Label template's
                        // own Padding="5".
                        .padding(EdgeInsets(top: 25, leading: 35, bottom: 25, trailing: 25))
                } else {
                    ForEach(Array(minions.prefix(7).enumerated()), id: \.offset) { _, minion in
                        BattlegroundsMinionRepresentable(entity: minion)
                            .frame(width: Self.minionWidth, height: Self.minionHeight)
                            .padding(.vertical, 15)
                    }
                }
            }
            .padding(.trailing, 10)
        }
        .fixedSize()
        .background(Color(hex: "#23272A"))
        .cornerRadius(3)
        // BorderBrush="#404345" BorderThickness="1 0 1 1"
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(hex: "#404345"), lineWidth: 1)
        )
    }

    // Border Name="FinalBoardArrow": a 14x14 square rotated 45 degrees, sitting
    // on the side of the box that faces the row.
    private var arrow: some View {
        Rectangle()
            .fill(Color(hex: "#23272A"))
            .frame(width: 14, height: 14)
            // FinalBoardArrowBorderThickness: (1,0,0,1) when the tooltip opens
            // to the right, (0,1,1,0) when it opens to the left - the two edges
            // that end up facing outward once the square is rotated.
            .overlay(
                ZStack {
                    if tooltipToRight {
                        Color(hex: "#404345").frame(width: 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        Color(hex: "#404345").frame(height: 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    } else {
                        Color(hex: "#404345").frame(height: 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        Color(hex: "#404345").frame(width: 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    }
                }
            )
            .rotationEffect(.degrees(45))
            .offset(x: tooltipToRight ? 0 : contentWidth + 2,
                    y: minions.isEmpty ? 70 : 135)
    }
}

// HSTracker draws a Battlegrounds minion (art, border, keyword badges and
// stats) with a custom NSView; there is no SwiftUI equivalent, so the final
// board hosts the existing view rather than re-implementing that drawing.
@available(macOS 10.15, *)
private struct BattlegroundsMinionRepresentable: NSViewRepresentable {
    let entity: Entity

    func makeNSView(context: Context) -> BattlegroundsMinionView {
        let view = BattlegroundsMinionView()
        view.entity = entity
        return view
    }

    func updateNSView(_ nsView: BattlegroundsMinionView, context: Context) {
        nsView.entity = entity
        nsView.needsDisplay = true
    }
}
