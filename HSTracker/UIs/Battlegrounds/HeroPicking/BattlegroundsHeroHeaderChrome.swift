//
//  BattlegroundsHeroHeaderChrome.swift
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

// The plate BattlegroundsHeroHeader.xaml draws behind its text: an Image whose
// Source is a DrawingImage, i.e. eight GeometryDrawings declared in their own
// 243x61 canvas - two purple-capped panels with a bite taken out of their inner
// bottom corner for the hero portrait to show through, and the tier square
// between them.
//
// Every path below is that XAML's Geometry data, point for point; each Shape
// maps the 243x61 canvas into whatever rectangle it is given the way the Image
// does, uniformly and centred (which at the Grid's own 243x60 means a hair
// under 1:1, with 2pt of slack down either side).
@available(macOS 10.15, *)
struct BattlegroundsHeroHeaderChrome: View {
    let tierGradient: LinearGradient

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Tier, drawn first so the panels either side overlap it rather
            // than the other way round.
            HeaderDrawing(.tierBox).fill(tierGradient)
            HeaderDrawing(.tierBoxOutline)
                .stroke(Color.black.opacity(0.18), lineWidth: 1)

            // Left panel
            HeaderDrawing(.leftPanel).fill(Color.tier7Black)
            HeaderDrawing(.leftPanelCap).fill(Color.tier7Purple)
            HeaderDrawing(.leftPanel).stroke(Color.tier7Purple, lineWidth: 1)

            // Right panel
            HeaderDrawing(.rightPanel).fill(Color.tier7Black)
            HeaderDrawing(.rightPanelCap).fill(Color.tier7Purple)
            HeaderDrawing(.rightPanel).stroke(Color.tier7Purple, lineWidth: 1)
        }
    }
}

// One GeometryDrawing, built in the drawing's own 243x61 canvas and then fitted
// into the rectangle the view is given - Image's default Stretch="Uniform".
@available(macOS 10.15, *)
private struct HeaderDrawing: Shape {
    enum Piece {
        case tierBox, tierBoxOutline
        case leftPanel, leftPanelCap
        case rightPanel, rightPanelCap
    }

    let piece: Piece

    init(_ piece: Piece) {
        self.piece = piece
    }

    // DrawingGroup ClipGeometry="M0,0 V61 H243 V0 H0 Z".
    private static let canvasSize = CGSize(width: 243, height: 61)

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

        let scale = min(rect.width / Self.canvasSize.width, rect.height / Self.canvasSize.height)
        let dx = rect.minX + (rect.width - Self.canvasSize.width * scale) / 2
        let dy = rect.minY + (rect.height - Self.canvasSize.height * scale) / 2
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
