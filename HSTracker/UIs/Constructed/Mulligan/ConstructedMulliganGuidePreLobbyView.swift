//
//  ConstructedMulliganGuidePreLobbyView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Bridges the existing ConstructedMulliganGuidePreLobbyViewModel - which is one
// of HSTracker's own `ViewModel`s, with the deck status lookups and the locking
// they need, driven from the deck picker watcher, scene transitions and the
// tracker's own teardown - onto SwiftUI. Rewriting it as an ObservableObject
// would mean redoing that threading; republishing its propertyChanged callback
// as an objectWillChange on the main queue does not.
@available(macOS 10.15, *)
final class ConstructedMulliganGuidePreLobbyObservable: ObservableObject {
    let viewModel = ConstructedMulliganGuidePreLobbyViewModel()

    // The element's own Visibility, which HDT drives through
    // _constructedMulliganGuidePreLobbyBehaviour.Show()/Hide(). Separate from
    // the view model's own `visibility`, which takes the badges away while a
    // modal is open or the player is already queuing.
    @Published private(set) var isShown = false

    // Whether the pre-lobby has been asked for at all, before the user's own
    // setting is applied - what the AppKit window tracked as `isVisible`. Kept
    // apart from isShown so that toggling the setting while the pre-lobby is up
    // takes effect on the next pass rather than latching it off for good.
    var isRequested = false {
        didSet { applyVisibility() }
    }

    func applyVisibility() {
        isShown = isRequested && Settings.showMulliganGuidePreLobby
    }

    init() {
        viewModel.propertyChanged = { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
}

// HDT's ConstructedMulliganGuidePreLobby: the row of badges it draws over the
// deck boxes in the constructed pre-lobby, telling you which decks the mulligan
// guide has data for. This replaces the AppKit window and the three NSStackViews
// it filled by hand.
@available(macOS 10.15, *)
struct ConstructedMulliganGuidePreLobbyView: View {
    @ObservedObject var model: ConstructedMulliganGuidePreLobbyObservable
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in.
    let canvasWidth: CGFloat

    private static let canvasHeight: CGFloat = 1080

    // _constructedMulliganGuidePreLobbyBehaviour:
    //   GetLeft    = Helper.GetScaledXPos(0.087, Width, ScreenRatio)
    //   GetTop     = Height * 0.217
    //   GetScaling = Height / 1080
    // The scaling is the one this subtree already applies, so only the position
    // is left.
    private static let leftFactor: CGFloat = 0.087
    private static let topFactor: CGFloat = 0.217

    // StackPanel Width="238" Height="96" Margin="0,0,3,0" per cell, and the
    // Border Padding="0,0,0,128" that separates one row of deck boxes from the
    // next.
    private static let cellWidth: CGFloat = 238
    private static let cellHeight: CGFloat = 96
    private static let cellSpacing: CGFloat = 3
    private static let rowBottomPadding: CGFloat = 128

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it draws nothing while hidden, which is what replaces the
        // window show/hide.
        ZStack(alignment: .topLeading) {
            Color.clear
            if model.isShown && model.viewModel.visibility {
                badges.offset(x: originX, y: originY)
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
    }

    private var badges: some View {
        let rows = model.viewModel.pageStatusRows
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: Self.cellSpacing) {
                    ForEach(rows[row].indices, id: \.self) { column in
                        cell(rows[row][column])
                    }
                }
                .padding(.bottom, Self.rowBottomPadding)
            }
        }
    }

    // One deck box's badge. The cell keeps its 238x96 slot whether or not there
    // is a badge in it - HDT's Visibility on this StackPanel is Hidden rather
    // than Collapsed - so the badges stay lined up with the deck boxes below
    // even on a page that is not full.
    private func cell(_ status: SingleDeckStatus) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            if status.visibility {
                badge(status)
                    .padding(.top, status.padding.top)
                    .padding(.leading, status.padding.left)
                    .padding(.trailing, status.padding.right)
                    .padding(.bottom, status.padding.bottom)
            }
        }
        .frame(width: Self.cellWidth, height: Self.cellHeight, alignment: .topTrailing)
    }

    // Border Background BorderBrush BorderThickness="1,0,0,1" CornerRadius="0,0,0,2"
    // HorizontalAlignment="Right", holding the icon and, for the focused deck,
    // the status label. Only the left and bottom edges are stroked, and only the
    // bottom-left corner is rounded, so the badge reads as hanging off the top
    // right of the deck box.
    private func badge(_ status: SingleDeckStatus) -> some View {
        HStack(spacing: 0) {
            if status.iconVisibility {
                Image(status.iconSource)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .padding(1)
            }
            if status.labelVisibility {
                Text(status.label)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.trailing, 6)
                    .padding(.bottom, 2)
            }
        }
        .fixedSize()
        .background(Color(hex: status.background))
        .cornerRadius(2, corners: [.bottomLeft])
        .overlay(
            BadgeEdges()
                .stroke(Color(hex: status.borderBrush), lineWidth: 1)
        )
    }

    // Canvas.SetLeft(element, Helper.GetScaledXPos(0.087, Width, ScreenRatio)).
    private var originX: CGFloat {
        let ratio = (4.0 / 3.0) / (canvasWidth / Self.canvasHeight)
        return SizeHelper.getScaledXPos(Self.leftFactor, width: canvasWidth, ratio: ratio)
    }

    // Canvas.SetTop(element, Height * 0.217), where Height is this subtree's 1080.
    private var originY: CGFloat {
        Self.canvasHeight * Self.topFactor
    }
}

// BorderThickness="1,0,0,1": the left and bottom edges only.
@available(macOS 10.15, *)
private struct BadgeEdges: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}
