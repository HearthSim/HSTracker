//
//  RoundedCorners.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// SwiftUI's .cornerRadius() rounds all four corners uniformly; several HDT
// guide panels round only the top (e.g. a header sitting flush atop a
// square-cornered body, matching its container's own top radius). Ported
// from the same helper already shipping in the sibling Arenasmith app.
struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

@available(macOS 10.15, *)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

@available(macOS 10.15, *)
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: RectCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let p1 = CGPoint(x: rect.minX, y: rect.minY) // Top Left
        let p2 = CGPoint(x: rect.maxX, y: rect.minY) // Top Right
        let p3 = CGPoint(x: rect.maxX, y: rect.maxY) // Bottom Right
        let p4 = CGPoint(x: rect.minX, y: rect.maxY) // Bottom Left

        path.move(to: CGPoint(x: p1.x + (corners.contains(.topLeft) ? radius : 0), y: p1.y))

        path.addLine(to: CGPoint(x: p2.x - (corners.contains(.topRight) ? radius : 0), y: p2.y))
        if corners.contains(.topRight) {
            path.addArc(center: CGPoint(x: p2.x - radius, y: p2.y + radius), radius: radius,
                        startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        }

        path.addLine(to: CGPoint(x: p3.x, y: p3.y - (corners.contains(.bottomRight) ? radius : 0)))
        if corners.contains(.bottomRight) {
            path.addArc(center: CGPoint(x: p3.x - radius, y: p3.y - radius), radius: radius,
                        startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        }

        path.addLine(to: CGPoint(x: p4.x + (corners.contains(.bottomLeft) ? radius : 0), y: p4.y))
        if corners.contains(.bottomLeft) {
            path.addArc(center: CGPoint(x: p4.x + radius, y: p4.y - radius), radius: radius,
                        startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        }

        path.addLine(to: CGPoint(x: p1.x, y: p1.y + (corners.contains(.topLeft) ? radius : 0)))
        if corners.contains(.topLeft) {
            path.addArc(center: CGPoint(x: p1.x + radius, y: p1.y + radius), radius: radius,
                        startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        }

        return path
    }
}
