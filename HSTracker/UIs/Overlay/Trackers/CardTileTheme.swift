//
//  CardTileTheme.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// Everything the four overlay bar themes vary, as data.
///
/// `CardBar` expresses this as four subclasses (`ClassicBar`, `FrostBar`,
/// `DarkBar`, `MinimalBar`) overriding drawing methods. The SwiftUI row has one
/// view and picks its numbers from here instead; the values are the subclasses'
/// own, carried over literally.
///
/// Every rect is authored against HDT's 217x34 `CardTile` box, in AppKit's
/// bottom-left origin - the same coordinates `CardBar` uses - and converted once,
/// where the layer is placed.
@available(macOS 10.15, *)
struct CardTileTheme {
    /// Folder under Resources/Themes/Bars.
    let directory: String

    /// How far the art, the fade and the created icon slide left to make room for
    /// the count box. `CardBar.imageOffset` / `fadeOffset` / `createdIconOffset`.
    let imageOffset: CGFloat
    let fadeOffset: CGFloat
    let createdIconOffset: CGFloat

    /// The card art's box, and whether it slides by `imageOffset` when the count
    /// box is up.
    let imageRect: CGRect
    let imageOffsetByCountBox: Bool

    /// The fade overlay's box, and the same question for it.
    let fadeRect: CGRect
    let fadeOffsetByCountBox: Bool

    /// Nudges the subclasses apply to shared rects.
    let costOffsetX: CGFloat
    let countTextOffsetX: CGFloat
    let legendaryIconOffsetX: CGFloat

    /// `ClassicBar` fixes the name's box instead of computing it from what else is
    /// on the row.
    let fixedCardNameRect: CGRect?

    /// `MinimalBar` draws no count box, blurs the full-width art across the whole
    /// row, and colours the count by rarity.
    let drawsCountBox: Bool
    let usesBlurredFullWidthArt: Bool
    let countColorFollowsRarity: Bool

    /// `CardBar.flashColor`, the tint of the flash a drawn card gets.
    let flashColor: Color

    /// `ClassicBar` is the only theme with a font of its own.
    let usesClassicNameFont: Bool

    /// The name never grows past 15 in any theme: `CardBar.addCardName(rect:)`
    /// fits it with `maxFontSize: 15.0`, and the `textFontSize` the bar subclasses
    /// set (18 in ClassicBar) is dead - nothing reads it.
    static let nameFontSize: CGFloat = 15

    static let frameRect = CGRect(x: 0, y: 0, width: 217, height: 34)
    static let gemRect = CGRect(x: 0, y: 0, width: 34, height: 34)
    static let boxRect = CGRect(x: 183, y: 0, width: 34, height: 34)
    static let mulliganWinrateBoxRect = CGRect(x: 136, y: 4, width: 54, height: 26)
    static let defaultImageRect = CGRect(x: 83, y: 0, width: 134, height: 34)
    static let countTextRect = CGRect(x: 196, y: 9, width: 14, height: 34)
    static let costTextRect = CGRect(x: 0, y: 9, width: 34, height: 34)
    static let badAsMultipleRect = CGRect(x: 17, y: 0, width: 34, height: 34)

    static let countFontSize: CGFloat = 17
    static let costFontSize: CGFloat = 20
    static let mulliganWinRateFontSize: CGFloat = 15

    /// `CardBar.countTextColor`.
    static let countTextColor = Color(red: 0.9221, green: 0.7215, blue: 0.2226)

    /// `CardBar` draws its text with an NSAttributedString `strokeWidth` of -2
    /// (-1 for the cost): a stroke of 2% of the font size painted along with the
    /// fill, which is about a third of a point at these sizes. `outlinedText`
    /// stacks 8 offset copies instead, so it needs a matching offset rather than
    /// its default full point - at 1pt the glyphs come out visibly fatter than
    /// the AppKit row's and bleed over the created icon beside them.
    static let outlineWidth: CGFloat = 0.2

    /// Where a text layer's baseline sits, given the box `CardBar` authored for it.
    ///
    /// Those boxes are taller than the row itself (the name's is y 10, height 30,
    /// against a 34-high row) and overflow it, so they are not a frame to lay text
    /// out in. Measuring `CardBar`'s own output against them shows what it
    /// actually does: the glyphs sit on the box's origin, i.e. the baseline lands
    /// at `34 - rect.minY`, whatever the font. Centring instead looks right in one
    /// theme and two points out in the others, because Belwe and ChunkFive centre
    /// differently.
    static func baselineY(for rect: CGRect) -> CGFloat {
        frameRect.height - rect.minY
    }

    /// How far below a text layer's top edge its first baseline falls, so a box
    /// can be positioned to put that baseline where `baselineY` wants it.
    static func ascent(_ fontName: String, size: CGFloat) -> CGFloat {
        (NSFont(name: fontName, size: size) ?? .systemFont(ofSize: size)).ascender
    }

    static let classic = CardTileTheme(
        directory: "classic",
        imageOffset: -19, fadeOffset: -19, createdIconOffset: -19,
        imageRect: CGRect(x: 108, y: 4, width: 108, height: 27), imageOffsetByCountBox: true,
        fadeRect: CGRect(x: 28, y: 0, width: 189, height: 34), fadeOffsetByCountBox: true,
        costOffsetX: 1, countTextOffsetX: 0, legendaryIconOffsetX: 0,
        fixedCardNameRect: CGRect(x: 38, y: 10, width: frameRect.width - boxRect.width - 38, height: 30),
        drawsCountBox: true, usesBlurredFullWidthArt: false, countColorFollowsRarity: false,
        flashColor: Color(red: 1, green: 0.647, blue: 0),
        usesClassicNameFont: true)

    static let frost = CardTileTheme(
        directory: "frost",
        imageOffset: -23, fadeOffset: -23, createdIconOffset: -23,
        imageRect: defaultImageRect.offsetBy(dx: -1, dy: 0), imageOffsetByCountBox: false,
        fadeRect: frameRect, fadeOffsetByCountBox: false,
        costOffsetX: 0, countTextOffsetX: 1, legendaryIconOffsetX: -1,
        fixedCardNameRect: nil,
        drawsCountBox: true, usesBlurredFullWidthArt: false, countColorFollowsRarity: false,
        flashColor: Color(red: 0.41, green: 0.65, blue: 0.88),
        usesClassicNameFont: false)

    static let dark = CardTileTheme(
        directory: "dark",
        imageOffset: -23, fadeOffset: -23, createdIconOffset: -23,
        imageRect: defaultImageRect, imageOffsetByCountBox: true,
        fadeRect: CGRect(x: 34, y: 0, width: 183, height: 34), fadeOffsetByCountBox: true,
        costOffsetX: 0, countTextOffsetX: 2, legendaryIconOffsetX: 0,
        fixedCardNameRect: nil,
        drawsCountBox: true, usesBlurredFullWidthArt: false, countColorFollowsRarity: false,
        flashColor: Color(red: 0.1922, green: 0.5255, blue: 0.8706),
        usesClassicNameFont: false)

    static let minimal = CardTileTheme(
        directory: "minimal",
        imageOffset: -23, fadeOffset: -23, createdIconOffset: -15,
        imageRect: frameRect, imageOffsetByCountBox: false,
        fadeRect: frameRect, fadeOffsetByCountBox: false,
        costOffsetX: 0, countTextOffsetX: 0, legendaryIconOffsetX: 0,
        fixedCardNameRect: nil,
        drawsCountBox: false, usesBlurredFullWidthArt: true, countColorFollowsRarity: true,
        flashColor: Color.white,
        usesClassicNameFont: false)

    /// `CardBar.factory()`, which picks the subclass from Settings.theme.
    static var current: CardTileTheme {
        switch Settings.theme {
        case "frost": return frost
        case "dark": return dark
        case "minimal": return minimal
        default: return classic
        }
    }

    /// `CardBar.textFont`. Every theme but classic writes names in ChunkFive, and
    /// each falls back to a script-appropriate face.
    var nameFontName: String {
        if Settings.isSimplifiedChinese {
            return "AR LisuGB Medium"
        } else if Settings.isAsianLanguage {
            return "NanumGothic"
        } else if Settings.isCyrillicLanguage {
            return usesClassicNameFont ? "Benguiat Rus" : "BenguiatBold"
        }
        return usesClassicNameFont ? "Belwe Bd BT" : "ChunkFive"
    }

    /// `CardBar.numbersFont`.
    static let numbersFontName = "ChunkFive"

    /// The same `NSFont` `CardBar` draws with, as a SwiftUI font.
    ///
    /// `Font.custom(_:size:)` measures identically here, so this is not a fix for
    /// anything - it just takes the size question off the table, since `custom`
    /// is documented to scale with the body text style on newer systems and the
    /// non-scaling `Font.custom(_:fixedSize:)` needs macOS 11, past this file's
    /// 10.15 baseline.
    static func font(_ name: String, size: CGFloat) -> Font {
        Font((NSFont(name: name, size: size) ?? .systemFont(ofSize: size)) as CTFont)
    }

    /// `CardBar.fitFontForSize`, which is what keeps a long card name inside its
    /// box - and, because the binary search stops once the bracket is narrower
    /// than a point and returns its lower bound, never quite reaches `maxSize`
    /// even when the text would fit at it. A name that fits comfortably still
    /// comes out at 14.125 rather than 15, so the search is ported rather than
    /// approximated with `minimumScaleFactor`, which would leave the SwiftUI row's
    /// text visibly larger than the AppKit one's.
    ///
    /// Measured against the authored 217x34 box: `CardBar` measures against the
    /// box already divided by the card size's ratio and then divides the fitted
    /// size by it again, which is the scale the finished row applies once.
    static func fittedFontSize(_ text: String, fontName: String, box: CGSize,
                               maxSize: CGFloat, minSize: CGFloat = 1) -> CGFloat {
        guard !text.isEmpty, maxSize > minSize else { return maxSize }
        let key = "\(fontName)|\(maxSize)|\(box.width)x\(box.height)|\(text)"
        if let cached = fittedSizeCache.withLock({ $0[key] }) { return cached }

        var low = minSize
        var high = maxSize
        while high - low > 1 {
            let mid = (low + high) / 2
            guard let font = NSFont(name: fontName, size: mid.rounded()) else { break }
            let context = NSStringDrawingContext()
            context.minimumScaleFactor = 0.01
            let fitted = NSAttributedString(string: text, attributes: [.font: font, .strokeWidth: -2.0])
                .boundingRect(with: box, options: [.usesFontLeading, .usesDeviceMetrics], context: context)
                .size
            if fitted.height <= box.height && fitted.width <= box.width {
                low = mid
            } else {
                high = mid
            }
        }
        let result = min(low, high)
        fittedSizeCache.withLock { $0[key] = result }
        return result
    }

    private static let fittedSizeCache = UnfairLockBox([String: CGFloat]())

    // MARK: - Theme images

    /// The theme PNGs, loaded once per theme+name. `CardBar` re-reads them from
    /// disk on every draw; a SwiftUI row re-renders far more often than that, so
    /// they are cached.
    static func image(_ filename: String, in directory: String) -> NSImage? {
        let key = "\(directory)/\(filename)"
        if let cached = imageCache.withLock({ $0[key] }) {
            return cached
        }
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let image = NSImage(contentsOfFile: "\(resourcePath)/Resources/Themes/Bars/\(key)")
        imageCache.withLock { $0[key] = image }
        return image
    }

    func image(_ filename: String) -> NSImage? {
        CardTileTheme.image(filename, in: directory)
    }

    /// Whether the theme ships the optional per-rarity variants, which is what
    /// `Settings.showRarityColors` needs to take effect - HDT's
    /// `hasAllOptionalFrames` / `hasAllOptionalGems` / `hasAllOptionalCountBoxes`.
    func hasRarityVariants(_ prefix: String) -> Bool {
        ["common", "rare", "epic", "legendary"].allSatisfy {
            image("\(prefix)_\($0).png") != nil
        }
    }

    private static let imageCache = UnfairLockBox([String: NSImage?]())
}

/// HDT's `ThemeManager.ThemeChanged`, which every `CardTile` subscribes to for
/// itself (`CardTile.Subscribe`) so that switching theme redraws the tiles
/// already on screen rather than the next ones built.
///
/// A SwiftUI view reading `Settings.theme` straight out of its body gets no such
/// redraw: the theme is not one of the view's own values, so when the tracker
/// republishes its cards SwiftUI compares the row it would build against the one
/// it holds, finds the same `Card` and the same row height, and skips the body
/// where the theme would have been re-read. The row then keeps the old theme's
/// art until something about the card itself changes - the "next refresh" a
/// theme switch used to wait for. Observing this object is the dependency that
/// was missing, and is what HDT's per-tile subscription amounts to.
@available(macOS 10.15, *)
final class OverlayThemeObserver: ObservableObject {
    static let shared = OverlayThemeObserver()

    /// What the deck-list rows draw with.
    @Published private(set) var cardTile: CardTileTheme = .current
    /// `Settings.theme` itself, for the theme art that is looked up by name -
    /// the counter frames and the Battlegrounds browser's bars. Kept separate
    /// from `cardTile.directory` because those two part ways for a theme name
    /// `CardTileTheme.current` does not know: it falls back to classic, while
    /// the art falls back per file to the `default` directory.
    @Published private(set) var name: String = Settings.theme

    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: Settings.theme_token),
            object: nil, queue: .main) { [weak self] _ in
                self?.cardTile = .current
                self?.name = Settings.theme
            }
    }
}

/// A tiny lock box, so the image cache is safe to touch from whichever thread
/// SwiftUI renders on.
final class UnfairLockBox<Value> {
    private var value: Value
    private let lock = UnfairLock()

    init(_ value: Value) {
        self.value = value
    }

    func withLock<T>(_ body: (inout Value) -> T) -> T {
        lock.around { body(&value) }
    }
}
