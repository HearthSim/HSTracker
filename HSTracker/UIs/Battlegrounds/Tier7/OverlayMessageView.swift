//
//  OverlayMessageView.swift
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

// Port of HDT's OverlayMessage.xaml: the Tier7-badged strip the pickers put
// under their stats to say which MMR bracket the numbers are drawn from, or
// that they could not be loaded.
//
// Takes the text rather than an OverlayMessageViewModel because that view model
// is shared with the quest and trinket pickers, which are still AppKit and so
// cannot be gated to the SwiftUI baseline an ObservableObject would need. The
// panel hosting this republishes the view model's changes instead.
@available(macOS 10.15, *)
struct OverlayMessageView: View {
    let text: String?

    var body: some View {
        // Visibility="{Binding Visibility}", which the view model ties to
        // whether it has any text.
        if let text = text, !text.isEmpty {
            message(text)
        }
    }

    private func message(_ text: String) -> some View {
        HStack(spacing: 0) {
            // The logo's own Border: Background and BorderBrush are both
            // Tier7Purple, so its 1pt border is simply 1pt more purple around
            // the Padding="5 5 4 4".
            Image("tier7-logo")
                .resizable()
                .frame(width: 16, height: 16)
                .padding(EdgeInsets(top: 6, leading: 6, bottom: 5, trailing: 5))
                .background(RoundedCorner(radius: 5, corners: [.topLeft, .bottomLeft])
                    .fill(Color.tier7Purple))
                // Margin="-1": it sits over the outer border rather than
                // inside it.
                .padding(-1)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize()
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 5, trailing: 8))
        }
        .background(RoundedRectangle(cornerRadius: 5).fill(Color.tier7Black))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.tier7Purple, lineWidth: 1))
    }
}
