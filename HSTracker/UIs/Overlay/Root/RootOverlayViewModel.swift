//
//  RootOverlayViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Single scaled canvas new SwiftUI overlay features attach to as children,
// instead of each feature owning its own window + hand-rolled height/1080
// scaling math (what every AppKit overlay, including the V1 mulligan guide,
// currently does individually). RootOverlayView derives scale/canvas size
// directly from its own measured bounds (GeometryReader) rather than from
// state pushed in here, so content authored at the 1080-tall reference
// (matching the rest of HSTracker's overlay scaling convention) lines up
// regardless of the window's aspect ratio.
class RootOverlayViewModel: ObservableObject {
    // HDT's two constructed mulligan guides, declared one after the other on
    // its own canvas. The V1 one covers every game type the V2 one does not -
    // everything outside Ranked and Friendly.
    let mulliganGuide = ConstructedMulliganGuideViewModel()
    let mulliganGuideV2 = ConstructedMulliganGuideV2ViewModel()
    let constructedMulliganPreLobbyWidget = ConstructedMulliganPreLobbyWidgetViewModel()
    // HDT's ConstructedMulliganGuidePreLobby, the badges over the deck boxes -
    // declared on its own canvas just after the two guides, and a separate
    // element from the pre-lobby widget above.
    let mulliganGuidePreLobby = ConstructedMulliganGuidePreLobbyObservable()
    let mulliganGuideTrialsExhausted = MulliganGuideTrialsExhaustedViewModel()
    let battlegroundsCompsGuides = BattlegroundsCompsGuidesViewModel()
    let battlegroundsHeroGuides = BattlegroundsHeroGuidesViewModel()
    let battlegroundsTrinketGuides = BattlegroundsTrinketGuidesViewModel()
    let battlegroundsAnomalyGuides = BattlegroundsAnomalyGuidesViewModel()
    let battlegroundsQuestGuides = BattlegroundsQuestGuidesViewModel()
    // HDT's DiscoveryGuidesTooltipTrigger, the element its trinket and quest
    // guide triggers share.
    let battlegroundsDiscoveryGuides = BattlegroundsDiscoveryGuidesViewModel()
    let battlegroundsMinionsGuide = BattlegroundsMinionsViewModel()
    let battlegroundsGuidesTabs = BattlegroundsGuidesTabsViewModel()
    let battlegroundsTurnCounter = BattlegroundsTurnCounterViewModel()
    let battlegroundsInspiration = BattlegroundsInspirationViewModel()
    let battlegroundsMinionPinning = BattlegroundsMinionPinningViewModel()
    let arenaPickHelper = ArenaPickHelperViewModel()
    let arenaPreDraft = ArenaPreDraftViewModel()
    let battlegroundsSession = BattlegroundsSessionViewModel()
    let bobsBuddy = BobsBuddyPanelViewModel()
    let battlegroundsNotifications = BattlegroundsNotificationsViewModel()
    let mulliganToast = MulliganToastViewModel()
    let battlegroundsOpponentInfo = BattlegroundsOpponentInfoViewModel()
    let battlegroundsHeroPicking = BattlegroundsHeroPickingViewModel()
    let battlegroundsQuestPicking = BattlegroundsQuestPickingViewModel()
    let battlegroundsTrinketPicking = BattlegroundsTrinketPickingViewModel()
    let tier7PreLobby = Tier7PreLobbyViewModel()

    // HDT's MercenariesTaskListVM, shared by its MercenariesTaskListButton and
    // MercenariesTaskListView - one view model for the pair here too, since the
    // button's only job is to reveal the list.
    let mercenariesTasks = MercenariesTaskListViewModel()
    // HDT's OverlayWindow.OpacityMaskOverlay, which it hands to the window's own
    // OpacityMask - the regions of the canvas cut away so what Hearthstone draws
    // over its board (a blown-up hovered card, its tooltips, the discover
    // choices, the friends list) is not covered by the overlay. See
    // RootOverlayViewModel+OpacityMask for the methods that fill it.
    let opacityMask = OverlayOpacityMask()

    // HDT's two CountersOverlay controls, IsPlayer="true"/"false".
    let playerCounters = CountersOverlayViewModel(isPlayer: true)
    let opponentCounters = CountersOverlayViewModel(isPlayer: false)

    // HDT's two ActiveEffectsOverlay controls, declared right after the
    // counters on its own canvas (Windows/OverlayWindow.xaml).
    let playerActiveEffects = ActiveEffectsOverlayViewModel(isPlayer: true)
    let opponentActiveEffects = ActiveEffectsOverlayViewModel(isPlayer: false)

    // HDT's two PlayerResourcesWidget controls, declared right after those on
    // the same canvas.
    let playerResources = PlayerResourcesViewModel(isPlayer: true)
    let opponentResources = PlayerResourcesViewModel(isPlayer: false)

    // HDT's three turn timers, LblTurnTime / LblPlayerTurnTime /
    // LblOpponentTurnTime, declared on the same canvas ahead of the deck lists.
    let turnTimer = TurnTimerOverlayViewModel()

    // HDT's IconBoardAttackOpponent and IconBoardAttackPlayer, declared
    // opponent-first just after the ExperienceCounter.
    let opponentBoardAttack = BoardAttackIconViewModel(isPlayer: false)
    let playerBoardAttack = BoardAttackIconViewModel(isPlayer: true)

    // HDT's ExperienceCounter, which sits on the same canvas right before that
    // pair of icons.
    let experienceCounter = ExperienceCounterViewModel()

    // HDT's GridFlavorText, the parchment panel a hovered card's flavor text is
    // drawn on.
    let flavorText = FlavorTextViewModel()

    // HDT's GridOpponentBoard and GridPlayerBoard: the seven hover slots per
    // side and the Mercenaries ability strips hanging off them.
    let boardOverlay = BoardOverlayViewModel()

    // HDT's MercAbility1/2/3, the three card renders it shows down the right
    // edge while a Mercenaries board minion is hovered.
    let mercenariesAbilityHover = MercenariesAbilityHoverViewModel()

    // HDT's Marks0..9, the age badges over the opponent's hand.
    let opponentHandMarkers = OpponentHandMarkersViewModel()

    // HDT's BorderStackPanelPlayer / BorderStackPanelOpponent - the two deck
    // trackers, which used to be windows of their own.
    let playerTracker = TrackerPanelViewModel(playerType: .player)
    let opponentTracker = TrackerPanelViewModel(playerType: .opponent)

    // What a hovered row in either tracker raises: the blown-up card render, the
    // related-cards grid and the player deck's synergy highlight. One per side,
    // since which side a row belongs to is all those need to know.
    let playerTrackerHover = TrackerCardHoverHandler(playerType: .player)
    let opponentTrackerHover = TrackerCardHoverHandler(playerType: .opponent)

    // HDT's SecretsContainer, the secret helper.
    let secretsPanel = SecretsPanelViewModel()

    // HDT's LinkOpponentDeckDisplay, which hangs off the bottom of the opponent
    // stack.
    let linkOpponentDeck = LinkOpponentDeckPanelViewModel()

    // Settings.windowsLocked, HDT's _uiMovable inverted. Mirrored here because
    // the trackers stop being click-through - and gain their drag and resize
    // grip - exactly while the overlay is unlocked, so the views have to
    // re-render when it is toggled.
    @Published var windowsLocked = Settings.windowsLocked
    private var windowsLockedObserver: NSObjectProtocol?

    init() {
        // HDT wires the same reference in OverlayWindow's constructor
        // (BattlegroundsMinionPinningViewModel.CompsGuidesVM = ...): the key
        // piece recommendations are mined out of the loaded comp guides.
        battlegroundsMinionPinning.compsGuides = battlegroundsCompsGuides

        // The two arena regions of the opacity mask, subscribed where HDT
        // subscribes them (OverlayWindow's constructor, next to its other
        // ArenaStateWatcher wiring) rather than from Watchers: they are the
        // overlay window's own, and ArenaStateEvent raises on the main queue
        // already. The rest of the mask is fed from Watchers because the
        // watchers behind it have a single `change` closure to spare.
        Watchers.arenaStateWatcher.onTrayBigCardChanged.subscribe { [weak self] in
            self?.setArenaCardOpacityMask($0)
        }
        Watchers.arenaStateWatcher.onTooltipChanged.subscribe { [weak self] in
            self?.setArenaTooltipOpacityMask($0)
        }

        windowsLockedObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name(rawValue: Settings.window_locked),
            object: nil, queue: .main) { [weak self] _ in
                self?.windowsLocked = Settings.windowsLocked
            }
    }

    deinit {
        if let windowsLockedObserver {
            NotificationCenter.default.removeObserver(windowsLockedObserver)
        }
    }

    // On-screen frames (in RootOverlayView's own coordinate space) of every
    // child that currently needs real mouse interactivity, reported by
    // InteractiveRegionPreferenceKey. RootOverlayWindow reads these to know
    // which pixels should stop being click-through. One rect per child rather
    // than their bounding box - see the preference key for why.
    @Published var interactiveRegions: [CGRect] = []

    // Frames of the children that want to know when the cursor is merely *over*
    // them, without claiming clicks. This is HDT's IsOverlayHoverVisible, the
    // counterpart to the IsOverlayHitTestVisible that interactiveRegions covers:
    // BgsTopBarMask is `IsHitTestVisible="False"` precisely so it can reveal the
    // minion browser's filter button on hover while every click in that corner
    // still falls through to Hearthstone, and the guide tooltips over the
    // offered heroes and quest rewards have to leave those cards clickable.
    //
    // Reported by HoverRegionPreferenceKey and matched against the cursor by
    // RootOverlayWindow, which tracks it continuously regardless of
    // ignoresMouseEvents - SwiftUI's own .onHover can't do this job, since it
    // only fires once the window has already stopped being click-through.
    @Published var hoverRegions: [HoverRegion] = []

    // The ids of the hover regions the cursor is currently inside, written by
    // RootOverlayWindow on every mouse move.
    @Published var hoveredRegionIds: Set<String> = [] {
        didSet {
            guard oldValue != hoveredRegionIds else { return }
            // HDT's StackPanelOpponent_MouseEnter / _MouseLeave, which are what
            // its IsOverlayHoverVisible stack panel raises
            // (Windows/OverlayWindow.xaml.cs): the link-opponent-deck prompt
            // follows the cursor onto the opponent's deck list.
            let id = TrackerPanelViewModel.opponentStackHoverRegionID
            if hoveredRegionIds.contains(id) && !oldValue.contains(id) {
                linkOpponentDeck.showByOpponentStack()
            } else if !hoveredRegionIds.contains(id) && oldValue.contains(id) {
                linkOpponentDeck.hideByOpponentStack()
            }
        }
    }

    // Every deck-tracker row currently on screen, reported by TrackerRowHoverKey.
    // RootOverlayWindow matches the cursor against these to raise a card's
    // preview - see its updateTrackerRowHover.
    @Published var trackerRows: [TrackerRowHover] = []

    // Frame of the Arena bottom panel, tracked separately from hoverRegions
    // above: those are reported by children that only need to know the cursor is
    // over them, while this one drives the panel's own slide-out and is matched
    // against the cursor by RootOverlayWindow on its own terms.
    @Published var arenaBottomPanelFrame: CGRect?

    // The bottom panel's direction funnel, in canvas pixels.
    @Published var arenaDirectionTriggerShape = [CGPoint]()
    @Published var arenaCardListDirectionShapes = [[CGPoint]]()
    @Published var arenaCardListTriggerFrame: CGRect?
    @Published var arenaTooltipRegions = [ArenaTooltipRegion]()

    // Where the board's hover ellipses and the player's hand cards currently
    // are, in canvas pixels. Tracked separately from hoverRegions because
    // BoardMouseOverDetection does more than ask whether the cursor is inside
    // one: it needs the shape, the side and the index to resolve an entity.
    @Published var boardHoverTargets: [BoardHoverTarget] = []
}
