//
//  MercenariesTaskListButtonView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's MercenariesTaskListButton: the "Tasks" plate with the Mercenaries
// portrait overlapping its right edge, which reveals the task list on hover.
// Replaces the 150x60 MercenariesTaskListButton NSPanel.
@available(macOS 10.15, *)
struct MercenariesTaskListButtonView: View {
    // Height="60" on the icon, which is the tallest thing in the Grid and so
    // sets the button's height. The image is 241x256 with a 72-dpi pHYs chunk,
    // and WPF's default Stretch="Uniform" derives its width from that aspect.
    private static let iconHeight: CGFloat = 60
    private static let iconAspect: CGFloat = 241.0 / 256.0

    // Margin="0,1,30,5" on the Border - the 30 on the right is what the icon
    // overlaps into.
    private static let plateMargin = EdgeInsets(top: 1, leading: 0, bottom: 5, trailing: 30)

    // Margin="20,0,40,0" and FontSize="18" on the TextBlock inside it.
    private static let labelMargin = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 40)
    private static let fontSize: CGFloat = 18

    var body: some View {
        ZStack(alignment: .trailing) {
            plate
            Image("merc_icon")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.iconHeight * Self.iconAspect, height: Self.iconHeight)
        }
        .frame(height: Self.iconHeight)
    }

    private var plate: some View {
        Text(String.localizedString("Tasks", comment: ""))
            .font(.system(size: Self.fontSize, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize()
            .padding(Self.labelMargin)
            .padding(MercenariesTaskView.borderThickness)
            // VerticalAlignment="Center" inside a Border that stretches to the
            // Grid's full height, less its own top and bottom margins.
            .frame(maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: MercenariesTaskView.cornerRadius)
                .fill(MercenariesTaskView.panelFill))
            .overlay(
                RoundedRectangle(cornerRadius: MercenariesTaskView.cornerRadius)
                    .strokeBorder(MercenariesTaskView.panelStroke,
                                  lineWidth: MercenariesTaskView.borderThickness)
            )
            .padding(Self.plateMargin)
    }
}
