//
//  BattlegroundsTierDetailsView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

@objc class BattlegroundsTierDetailsView: NSView {
    
    struct CardGroup {
        var tier: Int
        var minionType: Int
        var raceName: String
        var groupedByMinionType: Bool
        var cards: [Card]
    }
    
    var contentFrame = NSRect.zero
    lazy var _db = BattlegroundsDb()
    
    init() {
        super.init(frame: NSRect.zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private var internalGroups = [BattlegroundsCardsGroups]()
    var minionTypes: BattlegroundsMinionTypesBox?
    
    var availableRaces: [Race]?
    
    var unavailableRaces: [Race] {
        if let availableRaces {
            return _db.races.filter { x in !availableRaces.contains(x) && x != .invalid && x != .all }
        }
        return [Race]()
    }
    
    var activeTier: Int?
    
    var activeMinionType: Int?
    
    var isDuos: Bool = false
    
    var anomaly: String?
    
    var isThorimRelevant: Bool = false
            
    var availableTiers: [Int] {
        return BattlegroundsUtils.getAvailableTiers(anomalyCardId: anomaly)
    }
    
    var groups: [CardGroup] {
        var groups = [CardGroup]()
        
        if let tier = activeTier {
            let isTierAvailable = availableTiers.contains(tier)
            
            for race in _db.races {
                if let availableRaces, !availableRaces.contains(race) && race != .invalid {
                    continue
                }
                
                let cards = _db.getCards(tier, race, isDuos)
                
                if cards.count == 0 {
                    continue
                }
                
                groups.append(CardGroup(tier: tier, minionType: Race.lookup(race), raceName: String.localizedString("\(race)", comment: ""), groupedByMinionType: false, cards: cards.sorted(by: { (a, b) -> Bool in a.name < b.name })))
            }
                
            var spells = Settings.showTavernSpells ? _db.getSpells(tier, isDuos) : [Card]()
            if spells.count > 0 {
                spells = spells.compactMap { x in
                    if isTierAvailable {
                        return x
                    }
                    let ret = x.copy()
                    ret.count = 0
                    return ret
                }
                
                groups.append(CardGroup(tier: tier, minionType: -1, raceName: "", groupedByMinionType: false, cards: spells.sorted(by: { (a, b) -> Bool in
                    a.cost == b.cost ? a.name < b.name : a.cost < b.cost
                })))
            }
            return groups.sorted(by: { (a, b) -> Bool in
                let sort_a = switch a.minionType {
                case 26: // all
                    -1
                case 0: // invalid - neutral
                    1
                case -1: // spells
                    2
                default:
                    0
                }
                let sort_b = switch b.minionType {
                case 26: // all
                    -1
                case 0: // invalid - neutral
                    1
                case -1: // spells
                    2
                default:
                    0
                }
                return sort_a == sort_b ? a.raceName < b.raceName : sort_a < sort_b
            })
        } else if let minionType = activeMinionType {
            var tiers = availableTiers
            if AppDelegate.instance().coreManager.game.windowManager.battlegroundsTierOverlay.tierOverlay.showTavernTier7 {
                tiers.append(7)
            }
            for tierGroup in tiers {
                let race = Race(rawValue: minionType)
                let cards = minionType == -1 ? _db.getSpells(tierGroup, isDuos).sorted(by: { (a, b) -> Bool in a.cost < b.cost}).sorted(by: { (a, b) -> Bool in a.name < b.name }) : (_db.getCards(tierGroup, race ?? .invalid, isDuos) + (race != .all && race != .invalid ? _db.getCards(tierGroup, .all, isDuos) : [Card]())).sorted(by: { (a, b) -> Bool in a.name < b.name })
                if cards.count == 0 {
                    continue
                }
                groups.append(CardGroup(tier: tierGroup, minionType: minionType, raceName: "", groupedByMinionType: true, cards: cards))
            }
        }
        return groups
    }
    
    private var hoverTimer: Timer?
    
    func setTier(tier: Int, isThorimRelevant: Bool) {
        let game = AppDelegate.instance().coreManager.game
        self.activeTier = tier
        self.activeMinionType = nil
        self.availableRaces = game.availableRaces
        self.isThorimRelevant = isThorimRelevant
        self.isDuos = game.isBattlegroundsDuosMatch()
        let anomalyDbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: game.gameEntity)
        self.anomaly = Cards.by(dbfId: anomalyDbfId, collectible: false)?.id
        
        updateCardGroups()
    }
    
    private func filterByMinionType(_ race: Race) {
        self.activeTier = nil
        self.activeMinionType = Race.lookup(race)
        updateCardGroups()
    }
    
    private func updateCardGroups() {
        let cardGroups = self.groups

        for view in subviews {
            view.removeFromSuperview()
        }
        let showBD = Settings.showBattlecryDeathrattleOnTiers

        self.internalGroups.removeAll()
        for cg in cardGroups {
            let group = BattlegroundsCardsGroups(frame: NSRect.zero)
            group.cardsList?.delegate = self
            group.minionType = cg.minionType
            group.tier = cg.tier
            group.groupedByMinionType = cg.groupedByMinionType
            group.cards = cg.cards.compactMap { x in
                let ret = x.copy()
                ret.cost = -1
                ret.id = x.id
                ret.name = x.name
                ret.type = x.type
                if showBD {
                    ret.mechanics = x.mechanics
                }
                ret.count = x.count == -1 ? 0 : 1
                return ret
            }
            group.clickMinionTypeCommand = filterByMinionType
            group.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249.0), for: .vertical)
            group.setContentHuggingPriority(.defaultHigh, for: .vertical)
            addSubview(group)
            self.internalGroups.append(group)
        }
        minionTypes = nil
        if let unavailable = AppDelegate.instance().coreManager.game.unavailableRaces, activeTier != nil && activeMinionType == nil {
            let types = BattlegroundsMinionTypesBox(frame: NSRect.zero)
            types.minionTypes = unavailable
            addSubview(types)
            minionTypes = types
        }
        needsLayout = true
    }
    
    override func layout() {
        super.layout()
        
        var cardHeight = switch Settings.cardSize {
        case .tiny:
            CGFloat(kTinyRowHeight)
        case .small:
            CGFloat(kSmallRowHeight)
        case .medium:
            CGFloat(kMediumRowHeight)
        case .huge:
            CGFloat(kHighRowFrameWidth)
        case .big:
            CGFloat(kRowHeight)
        }
        var totalCards = 0
        for group in internalGroups {
            totalCards += group.cards.count
        }
        let typesSize = minionTypes?.intrinsicContentSize ?? NSSize(width: 0, height: 0)
        var totalHeight = 30.0 * CGFloat(groups.count) + CGFloat(totalCards) * cardHeight + typesSize.height
        if totalHeight > contentFrame.height {
            totalHeight = contentFrame.height
            cardHeight = (totalHeight - typesSize.height - 30.0 * CGFloat(groups.count)) / CGFloat(totalCards)
        }
        var y = contentFrame.height
        for group in internalGroups {
            group.cardHeight = cardHeight
            let h = 30.0 + CGFloat(group.cards.count) * cardHeight
            y -= h
            group.frame = NSRect(x: 0, y: y, width: frame.width, height: h)
            group.cardsList.updateFrames()
        }
        y -= typesSize.height
        minionTypes?.frame = NSRect(x: 0, y: y, width: frame.width, height: typesSize.height)
    }
}

// MARK: - CardCellHover
extension BattlegroundsTierDetailsView: CardCellHover {
    func hover(cell: CardBar, card: Card) {
        let windowRect = self.window!.frame

        let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)

        var x: CGFloat
        // decide if the popup window should on the left or right side of the tracker
        if windowRect.origin.x < hoverFrame.size.width {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }
        
        let tierFrame = SizeHelper.battlegroundsTierOverlayFrame()

        let cellFrameRelativeToWindow = cell.convert(cell.bounds, to: nil)
        let cellFrameRelativeToScreen = cell.window?.convertToScreen(cellFrameRelativeToWindow)

        var y: CGFloat = cellFrameRelativeToScreen!.origin.y
        if (y + hoverFrame.height/2) >= tierFrame.minY {
            y = tierFrame.minY - hoverFrame.height/2
        } else if (y - hoverFrame.height/2) < 0 {
            y = hoverFrame.height/2
        }

        let frame = [x, y - hoverFrame.height / 2.0, hoverFrame.width, hoverFrame.height]
        DispatchQueue.main.async {
            self.hoverTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(self.hoverGolden), userInfo: ["frame": frame, "cardId": card.id ], repeats: false)
        }

        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.show_floating_card),
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame,
                                    "battlegrounds": true,
                                    "useFrame": true
                ])
    }

    func out(card: Card) {
        hoverTimer?.invalidate()
        
        let userinfo = [
            "card": card
            ] as [String: Any]

        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil, userInfo: userinfo)
    }
    
    @objc func hoverGolden(_ timer: Timer) {
        if let dict = timer.userInfo as? [String: Any] {
            
            guard let cardId = dict["cardId"] as? String, let frame = dict["frame"] as? [CGFloat] else {
                return
            }
            
            let opaque = mono_thread_attach(MonoHelper._monoInstance)
            
            defer {
                mono_thread_detach(opaque)
            }
            
            let goldenCardId = MinionFactoryProxy.tryGetPremiumIdFromNormal(cardId)
            
            guard let card = Cards.any(byId: goldenCardId) else {
                return
            }
            
            card.baconTriple = true

            NotificationCenter.default
                .post(name: Notification.Name(rawValue: Events.show_floating_card),
                                      object: nil,
                                      userInfo: [
                                        "card": card,
                                        "frame": [ frame[0] - frame[2] - 22, frame[1], frame[2], frame[3] ],
                                        "battlegrounds": true,
                                        "useFrame": true,
                                        "index": 2
                    ])

        }
    }
}
