//
//  PickData.swift
//  HSTracker
//
//  Created by IHume on 2025-06-24.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct PickDataContainerRight: Shape {
    let portraitCurve: Bool;

    func path(in rect: CGRect) -> Path {
        Path { path in
            let curveOffset: CGFloat = 25
            let controlOffset: CGFloat = 22
            path.move(to: CGPoint(
                x: rect.maxX - (portraitCurve ? curveOffset + 12 : curveOffset + 8),
                y: rect.maxY
            ))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - curveOffset ))
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.maxX - (portraitCurve ? curveOffset + 12 : curveOffset + 8),
                    y: rect.maxY
                ),
                control: CGPoint(
                    x: rect.midX + (portraitCurve ? controlOffset + 3 : controlOffset + 3),
                    y: rect.midY + (portraitCurve ? controlOffset + 3 : controlOffset + 3))
            )
        }
    }
}

@available(macOS 10.15, *)
struct PickDataContainerLeft: Shape {
    let portraitCurve: Bool;

    func path(in rect: CGRect) -> Path {
        Path { path in
            let curveOffset: CGFloat = 25
            let controlOffset: CGFloat = 22
            path.move(to: CGPoint(
                x: rect.minX + (portraitCurve ? curveOffset + 12 : curveOffset + 8),
                y: rect.maxY
            ))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - curveOffset ))
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.minX + (portraitCurve ? curveOffset + 12 : curveOffset + 8),
                    y: rect.maxY),
                control: CGPoint(
                    x: rect.midX - (portraitCurve ? controlOffset + 3 : controlOffset + 3),
                    y: rect.midY + (portraitCurve ? controlOffset + 3 : controlOffset + 3))
            )
        }
    }
}

enum ClipDirection {
    case RightIcon
    case LeftIcon
    case RightPortrait
    case LeftPortrait
}

@available(macOS 10.15, *)
struct PickData: View {
    let title: String
    let value: String
    let color: Color
    let clipSide: ClipDirection?
    
    init(title: String, value: String, clipSide: ClipDirection?) {
        self.title = title
        self.value = value
        self.color = Color.white
        self.clipSide = clipSide
    }
    
    init(title: String, value: String, clipSide: ClipDirection?, color: Color?) {
        self.title = title
        self.value = value
        self.clipSide = clipSide
        self.color = color ?? Color.white
    }
    
    var body: some View {
        return ZStack{
            if clipSide == .RightIcon || clipSide == .RightPortrait {
                PickDataContainerRight(portraitCurve: clipSide == .RightPortrait)
                    .foregroundColor(Color("TrackerBackground"))
                    .frame(width: 100, height: 75)
            } else if clipSide == .LeftIcon || clipSide == .LeftPortrait {
                PickDataContainerLeft(portraitCurve: clipSide == .LeftPortrait)
                    .foregroundColor(Color("TrackerBackground"))
                    .frame(width: 100, height: 75)
            } else {
                Rectangle()
                    .foregroundColor(Color("TrackerBackground"))
                    .frame(width: 100, height: 75)
            }
            VStack(spacing: 0, content: {
                Text(title)
                    .font(Font.system(size: 11))
                    .foregroundColor(Color.white)
                    .frame(width: 100, height: 25)
                    .background(Color("PickHeader"))
                Text(value)
                    .foregroundColor(color)
                    .frame(width: 100, height: 50)
                    .font(Font.system(size: 20, weight: .bold))
            })
        }
        .frame(width: 100, height: 75)
        .cornerRadius(5)
    }
}

@available(macOS 10.15, *)
#Preview {
    VStack {
        HStack(spacing: 50, content: {
            PickData(title: "Pick Rate", value: "14.0%", clipSide: .RightIcon)
            PickData(title: "Pick Rate", value: "14.0%", clipSide: .LeftIcon)
        })
        HStack(spacing: 50, content: {
            PickData(title: "Pick Rate", value: "14.0%", clipSide: .RightPortrait)
            PickData(title: "Pick Rate", value: "14.0%", clipSide: .LeftPortrait)
        })

    }
    
}
