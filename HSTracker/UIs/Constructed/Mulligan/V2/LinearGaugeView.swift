//
//  LinearGaugeView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct MulliganTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// SF Symbols (Image(systemName:)) need macOS 11; drawn by hand so the
// mulligan V2 views can target macOS 10.15.
@available(macOS 10.15, *)
struct MulliganChevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

@available(macOS 10.15, *)
struct LinearGaugeView: View {
    @ObservedObject var viewModel: ConstructedMulliganV2SingleCardHeaderViewModel

    private let barWidth: CGFloat = 212
    private let barHeight: CGFloat = 20
    private let markerWidth: CGFloat = 10
    private let canvasHeight: CGFloat = 40

    @SwiftUI.State private var flashOpacity: Double = 0

    var body: some View {
        ZStack {
            pill

            if let leftBand = viewModel.leftBand, let bandsWidth = viewModel.bandsWidth, bandsWidth > 0 {
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: CGFloat(bandsWidth), height: 18.5)
                    .position(x: CGFloat(leftBand) + CGFloat(bandsWidth) / 2 + markerWidth / 2, y: canvasHeight / 2)
            }

            if let position = viewModel.currentHandPosition {
                let x = CGFloat(position) + markerWidth / 2
                flash(at: x)
                marker(at: x)
            }
        }
        .frame(width: barWidth, height: canvasHeight)
        .onReceive(viewModel.confidenceDidChange) {
            flashOpacity = 0.6
            withAnimation(.easeOut(duration: 1.5)) {
                flashOpacity = 0
            }
        }
    }

    private var pill: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: viewModel.negativeColor, location: 0),
                        .init(color: viewModel.neutralColor, location: 0.5),
                        .init(color: viewModel.positiveColor, location: 1)
                    ]),
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1))
            .frame(width: barWidth, height: barHeight)
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            .overlay(
                HStack {
                    Text(String.localizedString("MulliganGV2_Replace", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(String.localizedString("MulliganGV2_Keep", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 6)
                .frame(width: barWidth, height: barHeight)
            )
    }

    private func marker(at x: CGFloat) -> some View {
        VStack(spacing: 0) {
            MulliganTriangle()
                .fill(Color.white)
                .overlay(MulliganTriangle().stroke(Color.black, lineWidth: 1))
                .frame(width: 10, height: 8)
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 22)
        }
        .position(x: x, y: canvasHeight / 2)
    }

    private func flash(at x: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(flashOpacity))
            .frame(width: 20, height: barHeight)
            .position(x: x, y: canvasHeight / 2)
    }
}
