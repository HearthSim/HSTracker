//
//  ArenaVectorIcons.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// Builds a `Path` from the WPF path mini-language - the same syntax SVG's `d`
/// attribute uses.
///
/// HDT ships its Arenasmith badge icons as `DrawingImage` resources whose geometry
/// is a single string. Keeping that string verbatim, rather than transcribing the
/// curves into `addCurve` calls, means the artwork can be diffed against the XAML
/// it came from.
///
/// Only the commands those icons use are handled - move, line, horizontal and
/// vertical line, cubic curve and close, absolute and relative - plus the leading
/// `F0`/`F1` fill-rule marker, which is skipped: SwiftUI has no per-path fill rule,
/// and these shapes have no self-intersections for it to disambiguate.
@available(macOS 10.15, *)
enum ArenaVectorPath {
    static func path(from data: String) -> Path {
        var path = Path()
        let chars = Array(data)
        var index = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var command: Character = "M"

        func isDigit(_ char: Character) -> Bool { char >= "0" && char <= "9" }

        func skipSeparators() {
            while index < chars.count, chars[index] == " " || chars[index] == "," || chars[index].isNewline || chars[index] == "\t" {
                index += 1
            }
        }

        func readNumber() -> CGFloat? {
            skipSeparators()
            var text = ""
            if index < chars.count, chars[index] == "+" || chars[index] == "-" {
                text.append(chars[index])
                index += 1
            }
            var sawDigit = false
            while index < chars.count, isDigit(chars[index]) {
                text.append(chars[index])
                index += 1
                sawDigit = true
            }
            if index < chars.count, chars[index] == "." {
                text.append(chars[index])
                index += 1
                while index < chars.count, isDigit(chars[index]) {
                    text.append(chars[index])
                    index += 1
                    sawDigit = true
                }
            }
            guard sawDigit else { return nil }
            // An exponent only counts if digits actually follow it, so a trailing
            // "E" that turned out to be a command letter is left for the caller.
            if index < chars.count, chars[index] == "e" || chars[index] == "E" {
                var lookahead = index + 1
                var exponent = "e"
                if lookahead < chars.count, chars[lookahead] == "+" || chars[lookahead] == "-" {
                    exponent.append(chars[lookahead])
                    lookahead += 1
                }
                var sawExponentDigit = false
                while lookahead < chars.count, isDigit(chars[lookahead]) {
                    exponent.append(chars[lookahead])
                    lookahead += 1
                    sawExponentDigit = true
                }
                if sawExponentDigit {
                    text += exponent
                    index = lookahead
                }
            }
            return Double(text).map { CGFloat($0) }
        }

        func readPoint(relative: Bool) -> CGPoint? {
            guard let x = readNumber(), let y = readNumber() else { return nil }
            // All three points of a relative curve are offsets from the same
            // starting point, so `current` is deliberately not advanced here.
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while index < chars.count {
            let loopStart = index
            skipSeparators()
            guard index < chars.count else { break }

            if chars[index].isLetter {
                // The fill-rule marker is an "F" with a digit attached, not a
                // drawing command.
                if chars[index] == "F" || chars[index] == "f" {
                    index += 1
                    _ = readNumber()
                    continue
                }
                command = chars[index]
                index += 1
            }

            switch command {
            case "M", "m":
                guard let point = readPoint(relative: command == "m") else { break }
                path.move(to: point)
                current = point
                subpathStart = point
                // Further coordinate pairs after a move are implicit line-tos.
                command = command == "M" ? "L" : "l"
            case "L", "l":
                guard let point = readPoint(relative: command == "l") else { break }
                path.addLine(to: point)
                current = point
            case "H", "h":
                guard let x = readNumber() else { break }
                let point = CGPoint(x: command == "h" ? current.x + x : x, y: current.y)
                path.addLine(to: point)
                current = point
            case "V", "v":
                guard let y = readNumber() else { break }
                let point = CGPoint(x: current.x, y: command == "v" ? current.y + y : y)
                path.addLine(to: point)
                current = point
            case "C", "c":
                let relative = command == "c"
                guard let control1 = readPoint(relative: relative),
                      let control2 = readPoint(relative: relative),
                      let point = readPoint(relative: relative) else { break }
                path.addCurve(to: point, control1: control1, control2: control2)
                current = point
            case "Z", "z":
                path.closeSubpath()
                current = subpathStart
            default:
                break
            }

            // Nothing consumed - malformed data, or a command with no operands
            // left. Step past it rather than spin.
            if index == loopStart {
                index += 1
            }
        }

        return path
    }
}

/// One of HDT's `DrawingImage` icons: path data authored against a fixed viewbox,
/// scaled uniformly into whatever frame it is given and centred, which is what
/// WPF's default `Stretch="Uniform"` does for the `Image` elements these sit in.
@available(macOS 10.15, *)
struct ArenaVectorIcon: Shape {
    let base: Path
    let viewBox: CGSize

    func path(in rect: CGRect) -> Path {
        guard viewBox.width > 0, viewBox.height > 0 else { return Path() }
        let scale = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let width = viewBox.width * scale
        let height = viewBox.height * scale
        let transform = CGAffineTransform(translationX: rect.midX - width / 2,
                                          y: rect.midY - height / 2)
            .scaledBy(x: scale, y: scale)
        return base.applying(transform)
    }
}

/// The "has related cards" mark: HDT's `CardIcon`, a card outline with a flame on
/// its face. Geometry copied verbatim from `ArenaPickSingleCardOption.xaml`.
@available(macOS 10.15, *)
struct ArenaCardGlyph: Shape {
    /// The icon's own coordinate space, from the drawing's clip geometry.
    static let viewBox = CGSize(width: 29.0, height: 42.0)
    /// Its natural width when drawn at HDT's 18pt height.
    static let width: CGFloat = 18 * viewBox.width / viewBox.height
    static let height: CGFloat = 18

    private static let base = ArenaVectorPath.path(from: "F1 M29,42z M0,0z M24.375,0C26.4461,0,28.125,1.67893,28.125,3.75L28.125,37.5C28.1249,39.571,26.446,41.25,24.375,41.25L3.75,41.25C1.67898,41.25,8.4069E-05,39.571,0,37.5L0,3.75C0,1.67893,1.67893,1.05703E-07,3.75,0L24.375,0z M17.4707,8.73633C13.1752,7.14281 11.5901,7.09678 9.50488,8.55371 8.50418,9.23652 7.21195,10.4203 6.62793,11.1943 6.04415,11.9682 5.16845,12.8341 4.66797,13.1074 3.8756,13.5627 3.75,14.0176 3.75,16.2939 3.75,18.4793 3.95878,19.2987 5.04297,21.0742 5.75194,22.258 6.91994,23.852 7.62891,24.626 8.83812,25.9461 9.04656,25.9913 11.3818,25.7637 14.4262,25.445 15.8438,24.2159 15.8438,21.9395 15.8437,18.7527 13.9259,16.7039 11.7158,17.4775 11.0069,17.7052 10.9232,17.9333 11.2568,18.6162 11.8406,19.7998 11.7571,20.3005 10.9648,20.6191 9.88057,21.0744 8.75494,19.208 8.75488,16.9316 8.75488,15.156 8.87969,14.928 10.5479,13.8809 11.5487,13.2435 13.3,12.6513 14.5928,12.5146 16.8448,12.2415 16.8865,12.2879 17.8457,13.8359 19.1801,15.9304 19.7228,21.4843 18.7637,23.1689 17.8045,24.899 15.8027,26.6746 13.9678,27.4941 13.0503,27.9039 11.5483,28.632 10.6309,29.1328 9.71338,29.5881 8.62923,29.998 8.25391,29.998 7.87859,29.9981 7.42002,30.181 7.29492,30.4541 7.16943,30.6816 6.58553,30.9092 6.00195,30.9092 4.95953,30.9092 4.66764,31.5461 5.41797,32.0469 5.66818,32.229 7.04437,32.7303 8.50391,33.1855 11.298,34.0506 11.8823,34.005 17.0117,32.457 22.6418,30.7269 25.7694,23.2144 23.7676,16.2939 22.5165,12.1054 20.7235,9.92008 17.4707,8.73633z")

    func path(in rect: CGRect) -> Path {
        ArenaVectorIcon(base: Self.base, viewBox: Self.viewBox).path(in: rect)
    }
}

/// The synergy mark: HDT's `BoostIcon`, a pair of stacked up-arrows drawn as two
/// separate fills. Geometry copied verbatim from `ArenaPickSingleCardOption.xaml`.
@available(macOS 10.15, *)
struct ArenaBoostGlyph: Shape {
    static let viewBox = CGSize(width: 40.0, height: 42.0)
    static let width: CGFloat = 18
    static let height: CGFloat = 18

    private static let base: Path = {
        var path = ArenaVectorPath.path(from: "F1 M40,42z M0,0z M27.7383,12.8623C28.5238,12.2218,29.6829,12.2678,30.415,13L39.415,22 39.5479,22.1464C39.8393,22.502,40.0007,22.9493,40.001,23.413L40.002,25.583 39.9961,25.748C39.8732,27.3656,37.9391,28.1671,36.708,27.1103L36.5879,26.999 32.0039,22.414 32.0039,40C32.0039,41.1043,31.1082,41.9997,30.0039,42L28.0039,42C26.8994,42,26.0039,41.1045,26.0039,40L26.0039,22.414 21.416,27.0019C20.1959,28.2219,18.1364,27.4232,18.0078,25.7529L18.002,25.5888 18,23.415 18.0098,23.2177C18.0549,22.7594,18.2575,22.3285,18.5859,22L27.5859,13 27.7383,12.8623z")
        path.addPath(ArenaVectorPath.path(from: "F1 M40,42z M0,0z M9.73828,0.862256C10.5238,0.221776,11.6829,0.267802,12.415,0.999952L21.415,9.99995 21.5479,10.1464C21.8393,10.502,22.0007,10.9493,22.001,11.413L22.002,13.583 21.9961,13.748C21.8732,15.3656,19.9391,16.1671,18.708,15.1103L18.5879,14.999 14.0039,10.414 14.0039,34C14.0039,35.1043,13.1082,35.9997,12.0039,36L10.0039,36C8.89935,36,8.00393,35.1045,8.00391,34L8.00391,10.414 3.41602,15.0019C2.19586,16.2219,0.136386,15.4232,0.0078125,13.7529L0.00195312,13.5888 0,11.415 0.00976562,11.2177C0.0549273,10.7594,0.257496,10.3285,0.585938,9.99995L9.58594,0.999952 9.73828,0.862256z"))
        return path
    }()

    func path(in rect: CGRect) -> Path {
        ArenaVectorIcon(base: Self.base, viewBox: Self.viewBox).path(in: rect)
    }
}

// MARK: - deck rail

/// HDT's `BoostGeo` and `BoostSmallGeo`: the chevron-tailed tab behind a deck-rail
/// synergy marker, drawn pointing left and rotated 180 degrees for the right-hand
/// one. Geometry copied verbatim from `ArenaPickHelper.xaml`.
@available(macOS 10.15, *)
enum ArenaBoostTab {
    static let viewBox = CGSize(width: 65, height: 64)
    static let smallViewBox = CGSize(width: 61, height: 30)
    /// HDT's `BoostPen`, a flat-capped mitred white stroke authored against the
    /// viewbox above, so it scales with the tab rather than staying 8pt wide.
    static let penWidth: CGFloat = 8

    /// Blue: something already drafted improves the hovered pick.
    static let leftColor = Color(hex: "#205080")
    /// Orange: the hovered pick improves something already drafted.
    static let rightColor = Color(hex: "#805020")

    static let path = ArenaVectorPath.path(from: "F1 M65,64z M0,0z M22.4512,2L59.0078,2C60.7323,2,62.0811,3.37032,62.0811,5L62.0811,59 62.0771,59.1523C61.9962,60.7142,60.6783,62,59.0078,62L22.5508,62 22.3496,61.9932C21.4135,61.9333,20.5636,61.4599,20.0332,60.7197L19.9248,60.5566 2.52734,32.5791C1.9538,31.6567,1.93406,30.5101,2.46289,29.5742L2.57617,29.3896 19.874,3.36719C20.4011,2.57432,21.2833,2.06624,22.2559,2.00586L22.4512,2z")
    static let smallPath = ArenaVectorPath.path(from: "F1 M61,30z M0,0z M18.8711,2L56,2C57.6569,2,59,3.34314,59,4.99999L59,25C59,26.6568,57.6569,28,56,28L18.96,28C18.3837,28,17.821,27.8339,17.3389,27.5244L17.1367,27.3828 3.58301,17.0166C2.03175,15.8299,2.01931,13.5176,3.51075,12.3076L3.66016,12.1943 17.126,2.56055C17.6351,2.19632,18.2451,2.00001,18.8711,2z")
}

/// One boost tab, filled and stroked in its own coordinate space so the pen scales
/// with it, then clipped to the viewbox the way HDT's `ClipGeometry` does - the
/// stroke straddles the geometry's edge and would otherwise spill out.
@available(macOS 10.15, *)
struct ArenaBoostTabView: View {
    let color: Color
    /// The right-hand tab is the same drawing under a 180-degree rotation.
    let pointsRight: Bool
    var small = false

    private var viewBox: CGSize { small ? ArenaBoostTab.smallViewBox : ArenaBoostTab.viewBox }
    private var base: Path { small ? ArenaBoostTab.smallPath : ArenaBoostTab.path }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / viewBox.width, proxy.size.height / viewBox.height)
            let shape = ArenaVectorIcon(base: base, viewBox: viewBox)
            ZStack {
                shape.fill(color)
                shape.stroke(Color.white,
                             style: StrokeStyle(lineWidth: ArenaBoostTab.penWidth * scale,
                                                lineCap: .butt, lineJoin: .miter))
            }
            .clipped()
            .rotationEffect(.degrees(pointsRight ? 180 : 0))
        }
        .aspectRatio(viewBox.width / viewBox.height, contentMode: .fit)
    }
}
