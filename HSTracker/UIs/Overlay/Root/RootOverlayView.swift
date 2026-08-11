//
//  RootOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct RootOverlayView: View {
    @ObservedObject var viewModel: RootOverlayViewModel

    var body: some View {
        // GeometryReader measures the real, current bounds NSHostingView gives this
        // view directly - scale/canvas are derived from that measurement and the
        // whole scaled subtree is explicitly centered on it with .position(), rather
        // than relying on NSHostingView's implicit placement of a fixed-size (canvas,
        // pre-scale) root view within its actual (post-scale) bounds, which doesn't
        // reliably line up.
        GeometryReader { geometry in
            let scale = geometry.size.height / 1080
            let canvasWidth = scale > 0 ? geometry.size.width / scale : geometry.size.width

            ZStack {
                ConstructedMulliganGuideV2View(viewModel: viewModel.mulliganGuideV2)
                // Future SwiftUI overlay features attach here as additional children.
            }
            .frame(width: canvasWidth, height: 1080)
            .scaleEffect(scale, anchor: .center)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}
