//
//  HDTCanvasIcon.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT paints its icons as a Rectangle whose Fill (or OpacityMask) is a
// VisualBrush over the whole 76x76 Canvas the icon is declared in
// (Resources/Icons.xaml). VisualBrush stretches that entire canvas into the
// rectangle, so the glyph itself lands in a sub-rectangle scaled by
// Canvas.Width/76 and offset by Canvas.Left/76 - which is why a 14x14 settings
// rectangle draws a 7.2pt gear, not a 14pt one. HDTCanvasIcon reproduces that
// mapping so the call sites can keep the XAML's own rectangle dimensions.
@available(macOS 10.15, *)
struct HDTCanvasIcon<S: Shape>: View {
    let shape: S
    /// The Path's Canvas.Left/Top/Width/Height inside the 76x76 icon canvas.
    let canvasRect: CGRect
    /// The WPF Rectangle's Width/Height.
    let size: CGSize
    let color: Color

    var body: some View {
        Color.clear
            .frame(width: size.width, height: size.height)
            .overlay(
                shape
                    .fill(color)
                    .frame(width: size.width * canvasRect.width / 76,
                           height: size.height * canvasRect.height / 76)
                    .offset(x: size.width * canvasRect.minX / 76,
                            y: size.height * canvasRect.minY / 76),
                alignment: .topLeading
            )
    }
}

@available(macOS 10.15, *)
struct HDTGearShape: Shape {
    // Normalized from HDT's appbar_settings geometry (Resources/Icons.xaml).
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.5000, 0.1275))
        path.addCurve(to: p(0.5651, 0.1331), control1: p(0.5222, 0.1275), control2: p(0.5440, 0.1294))
        path.addLine(to: p(0.6189, 0.0000))
        path.addLine(to: p(0.7618, 0.0578))
        path.addLine(to: p(0.7080, 0.1909))
        path.addCurve(to: p(0.8091, 0.2920), control1: p(0.7479, 0.2178), control2: p(0.7822, 0.2521))
        path.addLine(to: p(0.9422, 0.2382))
        path.addLine(to: p(1.0000, 0.3811))
        path.addLine(to: p(0.8669, 0.4349))
        path.addCurve(to: p(0.8725, 0.5000), control1: p(0.8706, 0.4560), control2: p(0.8725, 0.4778))
        path.addCurve(to: p(0.8669, 0.5651), control1: p(0.8725, 0.5222), control2: p(0.8706, 0.5440))
        path.addLine(to: p(1.0000, 0.6189))
        path.addLine(to: p(0.9422, 0.7618))
        path.addLine(to: p(0.8091, 0.7080))
        path.addCurve(to: p(0.7187, 0.8016), control1: p(0.7846, 0.7443), control2: p(0.7540, 0.7760))
        path.addLine(to: p(0.7771, 0.9328))
        path.addLine(to: p(0.6363, 0.9956))
        path.addLine(to: p(0.5779, 0.8644))
        path.addCurve(to: p(0.5000, 0.8725), control1: p(0.5528, 0.8697), control2: p(0.5267, 0.8725))
        path.addCurve(to: p(0.4349, 0.8669), control1: p(0.4778, 0.8725), control2: p(0.4560, 0.8706))
        path.addLine(to: p(0.3811, 1.0000))
        path.addLine(to: p(0.2382, 0.9422))
        path.addLine(to: p(0.2920, 0.8091))
        path.addCurve(to: p(0.1909, 0.7080), control1: p(0.2522, 0.7822), control2: p(0.2178, 0.7478))
        path.addLine(to: p(0.0578, 0.7618))
        path.addLine(to: p(0.0000, 0.6189))
        path.addLine(to: p(0.1331, 0.5651))
        path.addCurve(to: p(0.1275, 0.5000), control1: p(0.1294, 0.5440), control2: p(0.1275, 0.5222))
        path.addCurve(to: p(0.1331, 0.4349), control1: p(0.1275, 0.4778), control2: p(0.1294, 0.4560))
        path.addLine(to: p(0.0000, 0.3811))
        path.addLine(to: p(0.0578, 0.2382))
        path.addLine(to: p(0.1909, 0.2920))
        path.addCurve(to: p(0.2813, 0.1984), control1: p(0.2154, 0.2557), control2: p(0.2460, 0.2240))
        path.addLine(to: p(0.2229, 0.0672))
        path.addLine(to: p(0.3637, 0.0044))
        path.addLine(to: p(0.4221, 0.1356))
        path.addCurve(to: p(0.5000, 0.1275), control1: p(0.4473, 0.1303), control2: p(0.4733, 0.1275))
        path.closeSubpath()
        // Second subpath: the hub. Wound against the rim, so the default
        // non-zero fill rule (WPF's own "F1") punches it out as a hole.
        path.move(to: p(0.5000, 0.2431))
        path.addCurve(to: p(0.2431, 0.5000), control1: p(0.3581, 0.2431), control2: p(0.2431, 0.3581))
        path.addCurve(to: p(0.5000, 0.7569), control1: p(0.2431, 0.6419), control2: p(0.3581, 0.7569))
        path.addCurve(to: p(0.7569, 0.5000), control1: p(0.6419, 0.7569), control2: p(0.7569, 0.6419))
        path.addCurve(to: p(0.5000, 0.2431), control1: p(0.7569, 0.3581), control2: p(0.6419, 0.2431))
        path.closeSubpath()
        return path
    }
}

@available(macOS 10.15, *)
struct HDTCloseShape: Shape {
    // Normalized from HDT's appbar_close_white geometry (Resources/Icons.xaml).
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.1500, 0.0000))
        path.addLine(to: p(0.5000, 0.3500))
        path.addLine(to: p(0.8500, 0.0000))
        path.addLine(to: p(1.0000, 0.1500))
        path.addLine(to: p(0.6500, 0.5000))
        path.addLine(to: p(1.0000, 0.8500))
        path.addLine(to: p(0.8500, 1.0000))
        path.addLine(to: p(0.5000, 0.6500))
        path.addLine(to: p(0.1500, 1.0000))
        path.addLine(to: p(0.0000, 0.8500))
        path.addLine(to: p(0.3500, 0.5000))
        path.addLine(to: p(0.0000, 0.1500))
        path.addLine(to: p(0.1500, 0.0000))
        path.closeSubpath()
        return path
    }
}

@available(macOS 10.15, *)
struct HDTQuestionShape: Shape {
    // Normalized from HDT's appbar_question geometry (Resources/Icons.xaml).
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.4688, 0.8000))
        path.addCurve(to: p(0.6250, 0.9000), control1: p(0.5550, 0.8000), control2: p(0.6250, 0.8448))
        path.addCurve(to: p(0.4688, 1.0000), control1: p(0.6250, 0.9552), control2: p(0.5550, 1.0000))
        path.addCurve(to: p(0.3125, 0.9000), control1: p(0.3825, 1.0000), control2: p(0.3125, 0.9552))
        path.addCurve(to: p(0.4688, 0.8000), control1: p(0.3125, 0.8448), control2: p(0.3825, 0.8000))
        path.closeSubpath()
        path.move(to: p(0.5000, 0.0000))
        path.addCurve(to: p(1.0000, 0.2800), control1: p(0.7761, 0.0000), control2: p(1.0000, 0.1143))
        path.addCurve(to: p(0.8125, 0.4800), control1: p(1.0000, 0.3400), control2: p(0.9375, 0.4400))
        path.addCurve(to: p(0.6250, 0.6400), control1: p(0.6875, 0.5200), control2: p(0.6250, 0.5737))
        path.addLine(to: p(0.6250, 0.7200))
        path.addLine(to: p(0.3125, 0.7200))
        path.addLine(to: p(0.3125, 0.6600))
        path.addCurve(to: p(0.5625, 0.4000), control1: p(0.3125, 0.5240), control2: p(0.5000, 0.4400))
        path.addCurve(to: p(0.6875, 0.2800), control1: p(0.6875, 0.3200), control2: p(0.6875, 0.3089))
        path.addCurve(to: p(0.5000, 0.1600), control1: p(0.6875, 0.2137), control2: p(0.6036, 0.1600))
        path.addCurve(to: p(0.3125, 0.2800), control1: p(0.3964, 0.1600), control2: p(0.3125, 0.2137))
        path.addLine(to: p(0.3125, 0.3400))
        path.addLine(to: p(0.0000, 0.3400))
        path.addLine(to: p(0.0000, 0.3000))
        path.addCurve(to: p(0.5000, 0.0000), control1: p(0.0000, 0.1343), control2: p(0.2239, 0.0000))
        path.closeSubpath()
        return path
    }
}
