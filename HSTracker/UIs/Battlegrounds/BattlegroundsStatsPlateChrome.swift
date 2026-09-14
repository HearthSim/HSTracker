//
//  BattlegroundsStatsPlateChrome.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
    static let tier7Black = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
}

// The plate the hero and trinket pickers draw behind their stats: an Image whose
// Source is a DrawingImage, i.e. eight GeometryDrawings declared in their own
// canvas - two purple-capped panels with a bite taken out of their inner bottom
// corner for the card underneath to show through, and the tier square between
// them.
//
// BattlegroundsHeroHeader.xaml and BattlegroundsSingleTrinket.xaml carry the
// same eight paths; the trinket's only difference is that its panels sit in a
// DrawingGroup translated 39pt down, which lifts the tier square clear of them
// (Layout below). Every path is that XAML's Geometry data, point for point, and
// each Shape maps the drawing's canvas into whatever rectangle it is given the
// way the Image does, uniformly and centred.
@available(macOS 10.15, *)
struct BattlegroundsStatsPlateChrome: View {
    enum Layout {
        // The hero header's own 243x61 canvas, fitted into the Grid's 243x60 -
        // a hair under 1:1, with 2pt of slack down either side.
        case heroHeader
        // The trinket plate: the same drawing with the panels pushed 39pt down,
        // 243x100 of content fitted into a Grid of exactly that size.
        case trinketPlate

        // The bounds of the drawing itself, which is what a DrawingImage sizes
        // itself to - not the (larger) ClipGeometry either XAML declares.
        var canvasSize: CGSize {
            switch self {
            case .heroHeader: return CGSize(width: 243, height: 61)
            case .trinketPlate: return CGSize(width: 243, height: 100)
            }
        }

        // The TranslateTransform on the trinket drawing's panel group.
        var panelOffsetY: CGFloat {
            switch self {
            case .heroHeader: return 0
            case .trinketPlate: return 39
            }
        }
    }

    let tierGradient: LinearGradient
    let layout: Layout

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Tier, drawn first so the panels either side overlap it rather
            // than the other way round.
            drawing(.tierBox).fill(tierGradient)
            drawing(.tierBoxOutline)
                .stroke(Color.black.opacity(0.18), lineWidth: 1)

            // Left panel
            drawing(.leftPanel).fill(Color.tier7Black)
            drawing(.leftPanelCap).fill(Color.tier7Purple)
            drawing(.leftPanel).stroke(Color.tier7Purple, lineWidth: 1)

            // Right panel
            drawing(.rightPanel).fill(Color.tier7Black)
            drawing(.rightPanelCap).fill(Color.tier7Purple)
            drawing(.rightPanel).stroke(Color.tier7Purple, lineWidth: 1)
        }
    }

    private func drawing(_ piece: PlateDrawing.Piece) -> PlateDrawing {
        return PlateDrawing(piece, layout: layout)
    }
}

// One GeometryDrawing, built in the drawing's own canvas and then fitted into
// the rectangle the view is given - Image's default Stretch="Uniform".
@available(macOS 10.15, *)
private struct PlateDrawing: Shape {
    enum Piece {
        case tierBox, tierBoxOutline
        case leftPanel, leftPanelCap
        case rightPanel, rightPanelCap

        // Everything but the tier square is in the group the trinket plate
        // translates down.
        var isPanel: Bool {
            switch self {
            case .tierBox, .tierBoxOutline: return false
            default: return true
            }
        }
    }

    let piece: Piece
    let layout: BattlegroundsStatsPlateChrome.Layout

    init(_ piece: Piece, layout: BattlegroundsStatsPlateChrome.Layout) {
        self.piece = piece
        self.layout = layout
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch piece {
        case .tierBox: Self.tierBox(&path)
        case .tierBoxOutline: Self.tierBoxOutline(&path)
        case .leftPanel: Self.leftPanel(&path)
        case .leftPanelCap: Self.leftPanelCap(&path)
        case .rightPanel: Self.rightPanel(&path)
        case .rightPanelCap: Self.rightPanelCap(&path)
        }
        if piece.isPanel, layout.panelOffsetY != 0 {
            path = path.applying(CGAffineTransform(translationX: 0, y: layout.panelOffsetY))
        }

        let canvasSize = layout.canvasSize
        let scale = min(rect.width / canvasSize.width, rect.height / canvasSize.height)
        let dx = rect.minX + (rect.width - canvasSize.width * scale) / 2
        let dy = rect.minY + (rect.height - canvasSize.height * scale) / 2
        return path.applying(CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale))
    }

    // MARK: - Geometry

    private static func tierBox(_ path: inout Path) {
        path.addRoundedRect(in: CGRect(x: 95, y: 0, width: 53, height: 53),
                            cornerSize: CGSize(width: 4, height: 4))
    }

    private static func tierBoxOutline(_ path: inout Path) {
        path.addRoundedRect(in: CGRect(x: 95.5, y: 0.5, width: 52, height: 52),
                            cornerSize: CGSize(width: 3.5, height: 3.5))
    }

    private static func leftPanel(_ path: inout Path) {
        path.move(to: CGPoint(x: 58.0589, y: 60.5))
        path.addLine(to: CGPoint(x: 4, y: 60.5))
        path.addCurve(to: CGPoint(x: 0.5, y: 57),
                      control1: CGPoint(x: 2.067, y: 60.5), control2: CGPoint(x: 0.5, y: 58.933))
        path.addLine(to: CGPoint(x: 0.5, y: 4))
        path.addCurve(to: CGPoint(x: 4, y: 0.5),
                      control1: CGPoint(x: 0.5, y: 2.067), control2: CGPoint(x: 2.067, y: 0.5))
        path.addLine(to: CGPoint(x: 85, y: 0.5))
        path.addCurve(to: CGPoint(x: 88.5, y: 4),
                      control1: CGPoint(x: 86.933, y: 0.5), control2: CGPoint(x: 88.5, y: 2.067))
        path.addLine(to: CGPoint(x: 88.5, y: 37.6269))
        path.addCurve(to: CGPoint(x: 85.0485, y: 43.9512),
                      control1: CGPoint(x: 88.5, y: 40.181), control2: CGPoint(x: 87.1951, y: 42.5617))
        path.addCurve(to: CGPoint(x: 62.4836, y: 59.0877),
                      control1: CGPoint(x: 73.4888, y: 51.434), control2: CGPoint(x: 65.914, y: 56.6721))
        path.addCurve(to: CGPoint(x: 58.0589, y: 60.5),
                      control1: CGPoint(x: 61.1843, y: 60.0026), control2: CGPoint(x: 59.6436, y: 60.5))
        path.closeSubpath()
    }

    private static func leftPanelCap(_ path: inout Path) {
        path.move(to: CGPoint(x: 0, y: 4))
        path.addCurve(to: CGPoint(x: 4, y: 0),
                      control1: CGPoint(x: 0, y: 1.79086), control2: CGPoint(x: 1.79086, y: 0))
        path.addLine(to: CGPoint(x: 85, y: 0))
        path.addCurve(to: CGPoint(x: 89, y: 4),
                      control1: CGPoint(x: 87.2091, y: 0), control2: CGPoint(x: 89, y: 1.79086))
        path.addLine(to: CGPoint(x: 89, y: 22))
        path.addLine(to: CGPoint(x: 0, y: 22))
        path.closeSubpath()
    }

    private static func rightPanel(_ path: inout Path) {
        path.move(to: CGPoint(x: 187.075, y: 60.5))
        path.addLine(to: CGPoint(x: 239, y: 60.5))
        path.addCurve(to: CGPoint(x: 242.5, y: 57),
                      control1: CGPoint(x: 240.933, y: 60.5), control2: CGPoint(x: 242.5, y: 58.933))
        path.addLine(to: CGPoint(x: 242.5, y: 4))
        path.addCurve(to: CGPoint(x: 239, y: 0.5),
                      control1: CGPoint(x: 242.5, y: 2.067), control2: CGPoint(x: 240.933, y: 0.5))
        path.addLine(to: CGPoint(x: 158, y: 0.5))
        path.addCurve(to: CGPoint(x: 154.5, y: 4),
                      control1: CGPoint(x: 156.067, y: 0.5), control2: CGPoint(x: 154.5, y: 2.067))
        path.addLine(to: CGPoint(x: 154.5, y: 35.6269))
        path.addCurve(to: CGPoint(x: 157.948, y: 41.9578),
                      control1: CGPoint(x: 154.5, y: 38.1807), control2: CGPoint(x: 155.805, y: 40.5601))
        path.addCurve(to: CGPoint(x: 182.462, y: 58.9542),
                      control1: CGPoint(x: 169.997, y: 49.817), control2: CGPoint(x: 178.643, y: 56.1079))
        path.addCurve(to: CGPoint(x: 187.075, y: 60.5),
                      control1: CGPoint(x: 183.799, y: 59.9508), control2: CGPoint(x: 185.413, y: 60.5))
        path.closeSubpath()
    }

    private static func rightPanelCap(_ path: inout Path) {
        path.move(to: CGPoint(x: 154, y: 4))
        path.addCurve(to: CGPoint(x: 158, y: 0),
                      control1: CGPoint(x: 154, y: 1.79086), control2: CGPoint(x: 155.791, y: 0))
        path.addLine(to: CGPoint(x: 239, y: 0))
        path.addCurve(to: CGPoint(x: 243, y: 4),
                      control1: CGPoint(x: 241.209, y: 0), control2: CGPoint(x: 243, y: 1.79086))
        path.addLine(to: CGPoint(x: 243, y: 22))
        path.addLine(to: CGPoint(x: 154, y: 22))
        path.closeSubpath()
    }
}
