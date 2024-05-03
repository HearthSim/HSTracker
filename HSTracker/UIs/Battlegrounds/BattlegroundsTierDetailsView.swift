//
//  BattlegroundsTierDetailsView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundMinion {
    let cardId: String
    let techLevel: Int
}

class BattlegroundsTierDetailsView: NSView {
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
    
    var groups = [BattlegroundsCardsGroups]()
    var minionTypes: BattlegroundsMinionTypesBox?
    
    func setTier(tier: Int, isThorimRelevant: Bool) {
        let game = AppDelegate.instance().coreManager.game
        var availableRaces = game.availableRaces
        availableRaces?.append(Race.all)
        var sortedRaces = [Race]()
        var races = [Race: String]()
        if let allRaces = availableRaces {
            for race in allRaces {
                races[race] = String.localizedString(race.rawValue, comment: "")
            }
        }
        races[.invalid] = String.localizedString("neutral", comment: "")
        sortedRaces = races.keys.sorted(by: { (a, b) -> Bool in
            return races[a] ?? "" < races[b] ?? ""
        })
        let isDuos = game.isBattlegroundsDuosMatch()
        let anomalyDbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: game.gameEntity)
        let anomalyCardId = Cards.by(dbfId: anomalyDbfId, collectible: false)?.id
        var availableTiers = BattlegroundsUtils.getAvailableTiers(anomalyCardId: anomalyCardId)
        if isThorimRelevant {
            availableTiers.append(7)
        }
        let bannedMinions = BattlegroundsUtils.getMinionsBannedByAnomaly(anomalyDbfId: anomalyDbfId) ?? [String]()
        let showBD = Settings.showBattlecryDeathrattleOnTiers
    
        let isTierAvailable = availableTiers.contains(tier)
        var groups = [BattlegroundsCardsGroups]()
        for race in sortedRaces {
            var cards = _db.getCards(tier, race, isDuos)
            if cards.count == 0 {
                continue
            }
            if !isTierAvailable || bannedMinions.count > 0 {
                cards = cards.compactMap { x in
                    if isTierAvailable && !bannedMinions.contains(x.id) {
                        return x
                    }
                    let ret = x.copy()
                    ret.count = -1
                    return ret
                }
            }
            let group = BattlegroundsCardsGroups(frame: NSRect.zero)
            group.cardsList.delegate = self
            group.title = races[race] ?? "Unknown"
            group.cards = cards.compactMap { x in
                let ret = Card()
                ret.cost = -1
                ret.id = x.id
                ret.name = x.name
                ret.type = x.type
                if showBD {
                    ret.mechanics = x.mechanics
                }
                ret.count = x.count == -1 ? 0 : 1
                return ret
            }.sorted(by: { (a, b) -> Bool in
                return a.name < b.name
            })
            group.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249.0), for: .vertical)
            group.setContentHuggingPriority(.defaultHigh, for: .vertical)
            groups.append(group)
        }
        
        let spellRaceMapping = BattlegroundsUtils.tavernSpellRaceMapping
        var spells = Settings.showTavernSpells ? _db.getSpells(tier, isDuos).filter { x in
            if let availableRaces, let spellRace = spellRaceMapping[x.id], !availableRaces.contains(spellRace) {
                return false
            }
            return true
        } : [Card]()
        if spells.count != 0 {
            spells = spells.compactMap { x in
                if isTierAvailable {
                    return x
                }
                let ret = x.copy()
                ret.count = -1
                return ret
            }
            let group = BattlegroundsCardsGroups(frame: NSRect.zero)
            group.cardsList.delegate = self
            group.title = String.localizedString("spells", comment: "")
            group.cards = spells.compactMap { x in
                let ret = Card()
                ret.cost = -1
                ret.id = x.id
                ret.name = x.name
                ret.type = x.type
                ret.count = x.count == -1 ? 0 : 1
                return ret
            }.sorted(by: { (a, b) -> Bool in
                return a.name < b.name
            })
            group.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(249.0), for: .vertical)
            group.setContentHuggingPriority(.defaultHigh, for: .vertical)
            groups.append(group)
        }

        for view in subviews {
            view.removeFromSuperview()
        }

        self.groups.removeAll()
        for group in groups {
            addSubview(group)
            self.groups.append(group)
        }
        minionTypes = nil
        if let unavailable = AppDelegate.instance().coreManager.game.unavailableRaces {
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
        for group in groups {
            totalCards += group.cards.count
        }
        let typesSize = minionTypes?.intrinsicContentSize ?? NSSize(width: 0, height: 0)
        var totalHeight = 30.0 * CGFloat(groups.count) + CGFloat(totalCards) * cardHeight + typesSize.height
        if totalHeight > contentFrame.height {
            totalHeight = contentFrame.height
            cardHeight = (totalHeight - typesSize.height - 30.0 * CGFloat(groups.count)) / CGFloat(totalCards)
        }
        var y = contentFrame.height
        for group in groups {
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
        let userinfo = [
            "card": card
            ] as [String: Any]

        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil, userInfo: userinfo)
    }
}
