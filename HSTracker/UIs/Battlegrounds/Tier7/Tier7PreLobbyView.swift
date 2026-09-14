//
//  Tier7PreLobbyView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Palette from HDT's Controls/Overlay/Battlegrounds/BattlegroundsResources.xaml.
@available(macOS 10.15, *)
private extension Color {
    static let tier7Black = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
    static let tier7Orange = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x0D / 255)
    static let tier7YellowButtonBackground = Color(red: 0xF1 / 255, green: 0xC0 / 255, blue: 0x40 / 255)
    static let tier7YellowButtonBackgroundHover = Color(white: 0xCC / 255)
    static let tier7YellowButtonForeground = Color(red: 0x26 / 255, green: 0x20 / 255, blue: 0x0F / 255)
    // The "Hover for more details" link colour, hard-coded in Tier7PreLobby.xaml.
    static let tier7AnonymousLink = Color(red: 0x07 / 255, green: 0x61 / 255, blue: 0x8B / 255)
    // Sale tag / sale tooltip accent (#b94038, #F22A1129 and the gradient stops).
    static let tier7SaleRed = Color(red: 0xB9 / 255, green: 0x40 / 255, blue: 0x38 / 255)
    static let tier7SaleTooltipDark = Color(red: 0x2A / 255, green: 0x11 / 255, blue: 0x29 / 255).opacity(0xF2 / 255)
    static let tier7SaleTooltipLight = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255).opacity(0xF2 / 255)
    // The #22FFFFFF / #19FFFFFF white washes the XAML uses for hover states and
    // the anonymous tooltip's caption strip.
    static let tier7HoverWash = Color.white.opacity(0x22 / 255)
    static let tier7CaptionWash = Color.white.opacity(0x19 / 255)
}

@available(macOS 10.15, *)
private struct Tier7WarningShape: Shape {
    // Normalized from HDT's appbar_warning geometry (Resources/Icons.xaml).
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.9587, 1.0000))
        path.addLine(to: p(0.0413, 1.0000))
        path.addCurve(to: p(0.0413, 0.8379), control1: p(0.0000, 0.9552), control2: p(0.0000, 0.8826))
        path.addLine(to: p(0.4376, 0.0448))
        path.addCurve(to: p(0.5873, 0.0448), control1: p(0.4790, 0.0000), control2: p(0.5460, 0.0000))
        path.addLine(to: p(0.9587, 0.8379))
        path.addCurve(to: p(0.9587, 1.0000), control1: p(1.0000, 0.8826), control2: p(1.0000, 0.9552))
        path.closeSubpath()
        path.move(to: p(0.4118, 0.2835))
        path.addLine(to: p(0.4559, 0.6752))
        path.addLine(to: p(0.5441, 0.6752))
        path.addLine(to: p(0.5882, 0.2835))
        path.addLine(to: p(0.4118, 0.2835))
        path.closeSubpath()
        path.move(to: p(0.5000, 0.7325))
        path.addCurve(to: p(0.4294, 0.8089), control1: p(0.4610, 0.7325), control2: p(0.4294, 0.7667))
        path.addCurve(to: p(0.5000, 0.8853), control1: p(0.4294, 0.8511), control2: p(0.4610, 0.8853))
        path.addCurve(to: p(0.5706, 0.8089), control1: p(0.5390, 0.8853), control2: p(0.5706, 0.8511))
        path.addCurve(to: p(0.5000, 0.7325), control1: p(0.5706, 0.7667), control2: p(0.5390, 0.7325))
        path.closeSubpath()
        return path
    }
}

@available(macOS 10.15, *)
private struct Tier7ChevronShape: Shape {
    // Normalized from HDT's chevron_up geometry (Resources/Icons.xaml). The
    // XAML sets Stretch="Fill" on the Path, so the glyph is squashed to a
    // square inside its 51.2x51.2 canvas slot before the VisualBrush maps that
    // canvas into a 16x8 rectangle - hence normalizing to the frame here
    // rather than preserving the glyph's own 1.64 aspect.
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.5384, 0.0347))
        path.addLine(to: p(0.9788, 0.7553))
        path.addCurve(to: p(0.9788, 0.8812), control1: p(1.0000, 0.7901), control2: p(1.0000, 0.8464))
        path.addLine(to: p(0.9274, 0.9652))
        path.addCurve(to: p(0.8506, 0.9654), control1: p(0.9062, 0.9999), control2: p(0.8718, 1.0000))
        path.addLine(to: p(0.5000, 0.3943))
        path.addLine(to: p(0.1494, 0.9654))
        path.addCurve(to: p(0.0726, 0.9652), control1: p(0.1282, 1.0000), control2: p(0.0938, 0.9999))
        path.addLine(to: p(0.0212, 0.8812))
        path.addCurve(to: p(0.0212, 0.7553), control1: p(0.0000, 0.8464), control2: p(0.0000, 0.7901))
        path.addLine(to: p(0.4616, 0.0348))
        path.addCurve(to: p(0.5384, 0.0347), control1: p(0.4828, 0.0000), control2: p(0.5172, 0.0000))
        path.closeSubpath()
        return path
    }
}

// The diagonal wedge that separates the SUBSCRIBE NOW button from its sale tag
// (Tier7PreLobby.xaml: a 15-wide Path over the button's 25pt height).
@available(macOS 10.15, *)
private struct Tier7SaleWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 10 / 15, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// The sale tooltip's pointer: HDT's `<Polygon Points="24,0 5,12 24,24"/>`.
@available(macOS 10.15, *)
private struct Tier7SaleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 5 / 24, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - View

// Port of HDT's Controls/Overlay/Battlegrounds/Tier7/Tier7PreLobby.xaml.
//
// Lives in RootOverlayView's *scaled* subtree, because HDT scales this control
// by Height/1080 (OverlayWindow.xaml.cs, _tier7PreLobbyBehavior.GetScaling).
// The canvas position that behavior computes is applied by the parent - see
// RootOverlayView - so this view just draws itself top-left aligned.
@available(macOS 10.15, *)
struct Tier7PreLobbyView: View {
    @ObservedObject var viewModel: Tier7PreLobbyViewModel

    // Whether the cursor is over the panel at all (HDT: IsMouseOver on
    // Tier7Panel, which reveals the settings cog) and over the anonymous
    // state's teaser block (HDT: IsMouseOver on HoverTrigger, which fades in
    // the big tooltip).
    @SwiftUI.State private var isPanelHovered = false
    @SwiftUI.State private var isTeaserHovered = false

    // HDT's UserControl is a fixed 800x630 and the anonymous tooltip Border
    // stretches to fill all of it, sharing its top-left corner with the
    // interactive panel.
    private static let controlSize = CGSize(width: 800, height: 630)

    var body: some View {
        // isShown/visibility are checked here, in a view holding its own
        // @ObservedObject on this view model, rather than by RootOverlayView
        // gating whether to instantiate this view at all - a parent's
        // @ObservedObject only re-renders on *its own* @Published changes, not
        // on a nested ObservableObject's.
        if viewModel.isShown && viewModel.visibility {
            ZStack(alignment: .topLeading) {
                if isTeaserHovered && viewModel.userState == .unknownPlayer {
                    anonymousTooltip
                }
                interactivePanel
            }
            .frame(width: Self.controlSize.width, height: Self.controlSize.height, alignment: .topLeading)
        }
    }

    // MARK: Anonymous tooltip

    private var anonymousTooltip: some View {
        ZStack(alignment: .topLeading) {
            Color.tier7Black
            // Margin="280 30 20 0", HorizontalAlignment=Left, VerticalAlignment=Top,
            // Stretch defaults to Uniform - so the image is fitted into the
            // 500x600 box those margins leave and pinned to its top-left.
            Image("PreLobby-Large")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.controlSize.width - 280 - 20,
                       height: Self.controlSize.height - 30,
                       alignment: .topLeading)
                .padding(EdgeInsets(top: 30, leading: 280, bottom: 0, trailing: 20))

            VStack {
                Spacer()
                (Text(String.localizedString("BattlegroundsPreLobby_AnonymousTooltip_Top", comment: ""))
                    + Text("\n")
                    + Text(String.localizedString("BattlegroundsPreLobby_AnonymousTooltip_Bottom", comment: "")))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.tier7CaptionWash)
            }
        }
        .frame(width: Self.controlSize.width, height: Self.controlSize.height)
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.tier7Purple, lineWidth: 1))
        // HDT: FadeAnimation Direction=Right, Distance=20, Duration=0:0:0.2 -
        // the panel slides in from 20pt to its right as it fades up. Driven by
        // the withAnimation in the teaser's own .onHover below.
        .transition(AnyTransition.opacity.combined(with: .offset(x: 20, y: 0)))
        .allowsHitTesting(false)
    }

    // MARK: Interactive panel

    private var interactivePanel: some View {
        VStack(spacing: 0) {
            header
            if !viewModel.isCollapsed {
                content
            }
        }
        .frame(minWidth: viewModel.panelMinWidth)
        // A rounded *background* rather than .cornerRadius(): a WPF Border
        // rounds its own corners without clipping its children, and the sale
        // tooltip deliberately escapes this panel to the right. .cornerRadius()
        // would clip it away entirely.
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.tier7Black))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.tier7Purple, lineWidth: 1))
        .fixedSize()
        .onHover { isPanelHovered = $0 }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }

    private var header: some View {
        HStack(spacing: 0) {
            // HDT's Tier7Logo control, whose LogoBrush defaults to Tier7Orange;
            // the bundled SVG is already drawn in that #FFB00D.
            Image("tier7-logo")
                .resizable()
                .frame(width: 16, height: 16)
            Text(String.localizedString("BattlegroundsPreLobby_InteractivePanel_Header", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize()
                .padding(.horizontal, 12)
            Spacer(minLength: 0)
            // Only while the cursor is over the panel, matching the XAML's
            // `Visibility="{Binding IsMouseOver, ElementName=Tier7Panel, ...
            // ConverterParameter=Hidden}"` - Hidden, so it keeps its space and
            // the header never reflows as it appears.
            headerButton(margin: EdgeInsets(top: -3, leading: 0, bottom: -3, trailing: 2)) {
                viewModel.showSettings()
            } label: {
                HDTCanvasIcon(shape: HDTGearShape(),
                              canvasRect: CGRect(x: 18.538, y: 18.5381, width: 38.9239, height: 38.9239),
                              size: CGSize(width: 14, height: 14),
                              color: .white)
            }
            .opacity(isPanelHovered ? 1 : 0)
            .allowsHitTesting(isPanelHovered)

            headerButton(margin: EdgeInsets(top: -3, leading: 0, bottom: -3, trailing: -6)) {
                viewModel.toggleCollapsed()
            } label: {
                // HDT swaps the resource ("chevron_" + up/down) rather than
                // rotating; chevron_down is chevron_up's exact mirror, so a
                // half turn is the same glyph.
                HDTCanvasIcon(shape: Tier7ChevronShape(),
                              canvasRect: CGRect(x: 25.1849, y: 23.3542, width: 51.2, height: 51.2),
                              size: CGSize(width: 16, height: 8),
                              color: .white)
                    .rotationEffect(.degrees(viewModel.isCollapsed ? 180 : 0))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.tier7Purple)
        .cornerRadius(4)
        // Margin="-1 -1 -1 0": the header bleeds over the panel's own 1pt
        // border on three sides.
        .padding(EdgeInsets(top: -1, leading: -1, bottom: 0, trailing: -1))
    }

    // The chevron/cog chrome: Padding="4 3", CornerRadius=3, a #22FFFFFF wash
    // on hover, then a negative Margin that cancels the vertical padding so
    // neither button makes the header any taller than its 16pt logo.
    private func headerButton<Label: View>(margin: EdgeInsets,
                                           action: @escaping () -> Void,
                                           @ViewBuilder label: () -> Label) -> some View {
        let content = label()
        return headerButtonBody(margin: margin, action: action, label: content)
    }

    private func headerButtonBody<Label: View>(margin: EdgeInsets,
                                               action: @escaping () -> Void,
                                               label: Label) -> some View {
        HoverButton(action: action) { isHovering in
            label
                .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                .background(isHovering ? Color.tier7HoverWash : Color.clear)
                .cornerRadius(3)
        }
        .padding(margin)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.userState {
        case .loading:
            Text(String.localizedString("BattlegroundsPreLobby_InteractivePanel_Loading", comment: ""))
                .tier7Body()
                .padding(16)
        case .unknownPlayer:
            unknownPlayerBody
        case .validPlayer:
            validPlayerBody
        case .subscribed:
            subscribedBody
        case .disabled:
            disabledBody
        }
    }

    private var unknownPlayerBody: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Image("PreLobby-Small")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 182)
                    .padding(.top, -8)
                HStack(spacing: 0) {
                    Text(String.localizedString("BattlegroundsPreLobby_InteractivePanel_Anonymous_Hover", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.tier7AnonymousLink)
                    Image("appbar_magnify_blue")
                        .resizable()
                        .frame(width: 17, height: 17)
                        .padding(.leading, 4)
                }
                .background(Color.tier7Black)
            }
            // HDT hangs the big tooltip off IsMouseOver of this block alone,
            // not of the whole panel.
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTeaserHovered = hovering
                }
            }
            Text(String.localizedString("BattlegroundsPreLobby_InteractivePanel_Anonymous_Hover_Details", comment: ""))
                .tier7Body()
                .padding(.top, 8)
        }
        .frame(width: 182)
        .padding(16)
    }

    private var validPlayerBody: some View {
        VStack(spacing: 0) {
            Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_Welcome", comment: ""), viewModel.username ?? ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tier7Orange)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsRemaining", comment: ""), viewModel.trialUsesRemaining ?? 0))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.trailing, 8)
                Text("i")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.tier7Black)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .guideTooltip(String.localizedString("BattlegroundsPreLobby_TrialsRemaining_Tooltip", comment: ""))
            }
            .padding(.top, 8)

            if viewModel.resetTimeVisibility {
                Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsResetsIn", comment: ""), viewModel.trialTimeRemaining ?? ""))
                    .tier7Body()
            }

            Text(String.localizedString("BattlegroundsPreLobby_Join", comment: ""))
                .tier7Body()
                .padding(.top, 8)

            subscribeButton
                .padding(.top, 8)

            switch viewModel.refreshSubscriptionState {
            case .signIn:
                alreadySubscribedLine(String.localizedString("BattlegroundsPreLobby_SignInToSubscription", comment: ""),
                                      enabled: true) {
                    viewModel.signIn()
                }
            case .refresh:
                alreadySubscribedLine(String.localizedString("BattlegroundsPreLobby_RefreshSubscription", comment: ""),
                                      enabled: viewModel.refreshAccountEnabled) {
                    viewModel.refreshAccount()
                }
            case .hidden:
                EmptyView()
            }
        }
        .frame(width: 230)
        .padding(16)
    }

    // HDT renders these as one wrapping TextBlock with an inline Hyperlink, so
    // the link sits on the same baseline as the lead-in with a single space
    // between them.
    private func alreadySubscribedLine(_ linkText: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(String.localizedString("BattlegroundsPreLobby_AlreadySubscribed", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
            Text(linkText)
                .font(.system(size: 12))
                .foregroundColor(enabled ? .white : .gray)
                .underline()
                .onTapGesture { if enabled { action() } }
        }
        .padding(.top, 8)
    }

    private var subscribeButton: some View {
        // Height=25, Style=SubscribeButton (#F1C040 on #26200F, bold, going
        // #CCCCCC on hover).
        HoverButton(action: { viewModel.subscribeNow() }, label: { isHovering in
            ZStack {
                (isHovering ? Color.tier7YellowButtonBackgroundHover : Color.tier7YellowButtonBackground)
                Text(verbatim: "SUBSCRIBE NOW")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.tier7YellowButtonForeground)
                if viewModel.saleTagVisibility {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        saleTag
                    }
                }
            }
            .frame(height: 25)
        })
        // The tooltip is a Canvas overlay in HDT: it escapes the button's own
        // bounds to the right (Canvas.Right="-250", Canvas.Top="-40") and must
        // not push the panel's layout around, hence an overlay rather than a
        // sibling in the VStack.
        .overlay(saleTooltipOverlay, alignment: .topLeading)
    }

    private var saleTag: some View {
        HStack(spacing: 0) {
            Tier7SaleWedge()
                .fill(Color.tier7SaleRed)
                .frame(width: 15)
            Text(String.localizedString("BattlegroundsPreLobby_SaleTag", comment: ""))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .frame(height: 25)
                .background(Color.tier7SaleRed)
                // DropShadowEffect Direction=315 (down-right), ShadowDepth=1,
                // Opacity=0.3, BlurRadius=2.
                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0.707, y: 0.707)
                // Margin="10 0 0 0" over a 15-wide wedge: the tag body
                // overlaps the wedge's diagonal by 5pt.
                .padding(.leading, -5)
        }
    }

    @ViewBuilder
    private var saleTooltipOverlay: some View {
        if viewModel.saleTagVisibility && viewModel.saleTooltipVisibility {
            // HDT lays these out on a Canvas whose own width is the 230-wide
            // content column and whose origin is the button's top-left:
            //   Polygon  Canvas.Right="-23" Canvas.Top="6"  (24 wide)
            //     -> x 230 + 23 - 24 = 229 .. 253,  y 6 .. 30
            //   Border   Canvas.Right="-250" Canvas.Top="-40" Width="227"
            //     -> x 230 + 250 - 227 = 253 .. 480,  y from -40
            // so the arrow's tip points back at the button's right edge and
            // the bubble hangs off to the right of the whole panel.
            ZStack(alignment: .topLeading) {
                Tier7SaleArrow()
                    .fill(Color.tier7SaleTooltipDark)
                    .frame(width: 24, height: 24)
                    .offset(x: 229, y: 6)
                saleTooltip
                    .offset(x: 253, y: -40)
            }
        }
    }

    private var saleTooltip: some View {
        // Both lines pick up the control-wide TextBlock style (white, centered,
        // wrapping); the description's MaxWidth=200 never binds, since the
        // 227-wide bubble's 20pt padding already leaves only 187.
        VStack(spacing: 0) {
            Text(String.localizedString("BattlegroundsPreLobby_SaleTooltip_Title", comment: ""))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            Text(viewModel.saleDescription)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(width: 227)
        .background(
            LinearGradient(gradient: Gradient(stops: [
                .init(color: .tier7SaleTooltipLight, location: 0),
                .init(color: .tier7SaleTooltipDark, location: 0.5),
                .init(color: .tier7SaleTooltipLight, location: 1)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.tier7SaleTooltipDark, lineWidth: 1))
        .overlay(
            HoverButton(action: { viewModel.closeSaleTooltip() }, label: { isHovering in
                Text(verbatim: "✕")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(isHovering ? Color.tier7HoverWash : Color.clear)
                    .cornerRadius(3)
            })
            // HDT: HorizontalAlignment=Right, VerticalAlignment=Top,
            // Margin="0 -12 -12 0" *inside* the bubble's 20pt padding, so the
            // box overhangs the padded content area by 12 and therefore sits
            // 8pt inside the bubble's own edges.
            .offset(x: -8, y: 8),
            alignment: .topTrailing
        )
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }

    private var subscribedBody: some View {
        VStack(spacing: 0) {
            Text(String.localizedString("BattlegroundsPreLobby_Subscribed_Tier7", comment: ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tier7Orange)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.allTimeHighMMRVisibility {
                VStack(spacing: 0) {
                    Text(String.localizedString("BattlegroundsPreLobby_Subscribed_AllTimeMMR", comment: ""))
                        .tier7Body()
                    // FontFamily="#Chunkfive" at 24pt. Text(verbatim:) so the
                    // digits aren't run through locale number formatting.
                    Text(verbatim: viewModel.allTimeHighMMR ?? "N/A")
                        .font(.custom("ChunkFive", size: 24))
                        .foregroundColor(.white)
                        .fixedSize()
                }
                .padding(.top, 8)
            }

            // Tier7ButtonStyle: #F1C040 on #26200F, bold, 4pt padding, going
            // #CCCCCC on hover, with the label nudged 1pt up off the baseline.
            HoverButton(action: { viewModel.myStats() }, label: { isHovering in
                Text(String.localizedString("BattlegroundsPreLobby_Subscribed_MyStats", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.tier7YellowButtonForeground)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 5, trailing: 4))
                    .frame(maxWidth: .infinity)
                    .background(isHovering ? Color.tier7YellowButtonBackgroundHover : Color.tier7YellowButtonBackground)
            })
            .padding(.top, 8)
        }
        .frame(width: 230)
        .padding(16)
    }

    private var disabledBody: some View {
        // DockPanel: the warning glyph docks right, the message takes the rest.
        HStack(alignment: .top, spacing: 0) {
            Text(String.localizedString("BattlegroundsPreLobby_Disabled", comment: ""))
                .tier7Body()
            HDTCanvasIcon(shape: Tier7WarningShape(),
                          canvasRect: CGRect(x: 16.0256, y: 14.4489, width: 43.9488, height: 40.9682),
                          size: CGSize(width: 17, height: 15),
                          color: .tier7Orange)
                .padding(.leading, 4)
        }
        .frame(width: 182)
        .padding(16)
    }
}

// The XAML's default TextBlock style for this control: white, centered, 12pt,
// wrapping.
@available(macOS 10.15, *)
private extension View {
    func tier7Body() -> some View {
        self.font(.system(size: 12))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

// A plain-styled button whose label needs to know whether the cursor is over
// it - WPF gets this for free from the ControlTemplate's IsMouseOver trigger,
// and several of the controls above (the header chevron/cog, both yellow
// buttons, the sale tooltip's close box) key their background off it.
@available(macOS 10.15, *)
struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: (Bool) -> Label

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            label(isHovering)
                // Unfilled regions of a label are not hit-testable on their
                // own, so give every one of these a solid hit area.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
