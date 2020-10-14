//
//  BattlegroundsTierDetailsView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import kotlin_hslog

class BattlegroundsTierDetailsView: NSStackView {
    let battlegroundsMinions = [
        BattlegroundMinion(cardId: "AT_121", techLevel: 3), // Crowd Favorite
        BattlegroundMinion(cardId: "BGS_001", techLevel: 2), // Nathrezim Overseer
        BattlegroundMinion(cardId: "BGS_002", techLevel: 3), // Soul Juggler
        BattlegroundMinion(cardId: "BGS_004", techLevel: 1), // Wrath Weaver
        BattlegroundMinion(cardId: "BGS_006", techLevel: 5), // Sneed's Old Shredder
        BattlegroundMinion(cardId: "BGS_008", techLevel: 6), // Ghastcoiler
        BattlegroundMinion(cardId: "BGS_009", techLevel: 5), // Lightfang Enforcer
        BattlegroundMinion(cardId: "BGS_010", techLevel: 5), // Annihilan Battlemaster
        BattlegroundMinion(cardId: "BGS_012", techLevel: 6), // Kangor's Apprentice
        BattlegroundMinion(cardId: "BGS_014", techLevel: 2), // Imprisoner
        BattlegroundMinion(cardId: "BGS_017", techLevel: 2), // Pack Leader
        BattlegroundMinion(cardId: "BGS_018", techLevel: 6), // Goldrinn, the Great Wolf
        BattlegroundMinion(cardId: "BGS_019", techLevel: 1), // Red Whelp
        BattlegroundMinion(cardId: "BGS_020", techLevel: 4), // Primalfin Lookout
        BattlegroundMinion(cardId: "BGS_021", techLevel: 5), // Mama Bear
        BattlegroundMinion(cardId: "BGS_022", techLevel: 6), // Zapp Slywick
        BattlegroundMinion(cardId: "BGS_023", techLevel: 3), // Piloted Shredder
        BattlegroundMinion(cardId: "BGS_027", techLevel: 1), // Micro Machine
        BattlegroundMinion(cardId: "BGS_028", techLevel: 2), // Pogo-Hopper
        BattlegroundMinion(cardId: "BGS_029", techLevel: 3), // Shifter Zerus
        BattlegroundMinion(cardId: "BGS_030", techLevel: 5), // King Bagurgle
        BattlegroundMinion(cardId: "BGS_032", techLevel: 4), // Herald of Flame
        BattlegroundMinion(cardId: "BGS_033", techLevel: 3), // Hangry Dragon
        BattlegroundMinion(cardId: "BGS_034", techLevel: 3), // Bronze Warden
        BattlegroundMinion(cardId: "BGS_035", techLevel: 2), // Waxrider Togwaggle
        BattlegroundMinion(cardId: "BGS_036", techLevel: 5), // Razorgore, the Untamed
        BattlegroundMinion(cardId: "BGS_037", techLevel: 2), // Steward of Time
        BattlegroundMinion(cardId: "BGS_038", techLevel: 3), // Twilight Emissary
        BattlegroundMinion(cardId: "BGS_039", techLevel: 1), // Dragonspawn Lieutenant
        BattlegroundMinion(cardId: "BGS_040", techLevel: 6), // Nadina the Red
        BattlegroundMinion(cardId: "BGS_041", techLevel: 6), // Kalecgos, Arcane Aspect
        BattlegroundMinion(cardId: "BGS_043", techLevel: 5), // Murozond
        BattlegroundMinion(cardId: "BGS_044", techLevel: 6), // Imp Mama
        BattlegroundMinion(cardId: "BGS_045", techLevel: 2), // Glyph Guardian
        BattlegroundMinion(cardId: "BGS_046", techLevel: 5), // Nat Pagle, Extreme Angler
        BattlegroundMinion(cardId: "BGS_047", techLevel: 6), // Dread Admiral Eliza
        BattlegroundMinion(cardId: "BGS_048", techLevel: 4), // Southsea Strongarm
        BattlegroundMinion(cardId: "BGS_049", techLevel: 2), // Freedealing Gambler
        BattlegroundMinion(cardId: "BGS_053", techLevel: 3), // Bloodsail Cannoneer
        BattlegroundMinion(cardId: "BGS_055", techLevel: 1), // Deck Swabbie
        BattlegroundMinion(cardId: "BGS_056", techLevel: 4), // Ripsnarl Captain
        BattlegroundMinion(cardId: "BGS_060", techLevel: 3), // Yo-Ho-Ogre
        BattlegroundMinion(cardId: "BGS_061", techLevel: 1), // Scallywag
        BattlegroundMinion(cardId: "BGS_066", techLevel: 4), // Goldgrubber
        BattlegroundMinion(cardId: "BGS_067", techLevel: 4), // Drakonid Enforcer
        BattlegroundMinion(cardId: "BGS_069", techLevel: 6), // Amalgadon
        BattlegroundMinion(cardId: "BGS_071", techLevel: 3), // Deflect-o-Bot
        BattlegroundMinion(cardId: "BGS_072", techLevel: 5), // Cap'n Hoggarr
        BattlegroundMinion(cardId: "BGS_075", techLevel: 2), // Rabid Saurolisk
        BattlegroundMinion(cardId: "BGS_078", techLevel: 3), // Monstrous Macaw
        BattlegroundMinion(cardId: "BGS_079", techLevel: 6), // The Tide Razor
        BattlegroundMinion(cardId: "BGS_080", techLevel: 5), // Seabreaker Goliath
        BattlegroundMinion(cardId: "BGS_081", techLevel: 3), // Salty Looter
        BattlegroundMinion(cardId: "BGS_082", techLevel: 2), // Menagerie Mug
        BattlegroundMinion(cardId: "BGS_083", techLevel: 4), // Menagerie Jug
        BattlegroundMinion(cardId: "BGS_100", techLevel: 5), // Lil' Rag
        BattlegroundMinion(cardId: "BGS_104", techLevel: 5), // Nomi, Kitchen Nightmare
        BattlegroundMinion(cardId: "BGS_105", techLevel: 4), // Majordomo Executus
        BattlegroundMinion(cardId: "BGS_115", techLevel: 1), // Sellemental
        BattlegroundMinion(cardId: "BGS_116", techLevel: 1), // Refreshing Anomaly
        BattlegroundMinion(cardId: "BGS_119", techLevel: 3), // Crackling Cyclone
        BattlegroundMinion(cardId: "BGS_120", techLevel: 2), // Party Elemental
        BattlegroundMinion(cardId: "BGS_121", techLevel: 6), // Gentle Djinni
        BattlegroundMinion(cardId: "BGS_122", techLevel: 3), // Stasis Elemental
        BattlegroundMinion(cardId: "BGS_123", techLevel: 5), // Tavern Tempest
        BattlegroundMinion(cardId: "BGS_124", techLevel: 6), // Lieutenant Garr
        BattlegroundMinion(cardId: "BGS_126", techLevel: 4), // Wildfire Elemental
        BattlegroundMinion(cardId: "BGS_127", techLevel: 2), // Molten Rock
        BattlegroundMinion(cardId: "BGS_128", techLevel: 3), // Arcane Assistant
        BattlegroundMinion(cardId: "BGS_131", techLevel: 4), // Deadly Spore
        BattlegroundMinion(cardId: "BOT_218", techLevel: 4), // Security Rover
        BattlegroundMinion(cardId: "BOT_312", techLevel: 3), // Replicating Menace
        BattlegroundMinion(cardId: "BOT_537", techLevel: 4), // Mechano-Egg
        BattlegroundMinion(cardId: "BOT_606", techLevel: 2), // Kaboom Bot
        BattlegroundMinion(cardId: "BOT_911", techLevel: 4), // Annoy-o-Module
        BattlegroundMinion(cardId: "BRM_006", techLevel: 3), // Imp Gang Boss
        BattlegroundMinion(cardId: "BT_010", techLevel: 3), // Felfin Navigator
        BattlegroundMinion(cardId: "CFM_315", techLevel: 1), // Alleycat
        BattlegroundMinion(cardId: "CFM_316", techLevel: 3), // Rat Pack
        BattlegroundMinion(cardId: "CFM_610", techLevel: 3), // Crystalweaver
        BattlegroundMinion(cardId: "CFM_816", techLevel: 4), // Virmen Sensei
        BattlegroundMinion(cardId: "DAL_077", techLevel: 4), // Toxfin
        BattlegroundMinion(cardId: "DAL_575", techLevel: 3), // Khadgar
        BattlegroundMinion(cardId: "DAL_742", techLevel: 4), // Whirlwind Tempest
        BattlegroundMinion(cardId: "DS1_070", techLevel: 3), // Houndmaster
        BattlegroundMinion(cardId: "EX1_062", techLevel: 2), // Old Murk-Eye
        BattlegroundMinion(cardId: "EX1_093", techLevel: 4), // Defender of Argus
        BattlegroundMinion(cardId: "EX1_103", techLevel: 3), // Coldlight Seer
        BattlegroundMinion(cardId: "EX1_185", techLevel: 4), // Siegebreaker
        BattlegroundMinion(cardId: "EX1_506", techLevel: 1), // Murloc Tidehunter
        BattlegroundMinion(cardId: "EX1_507", techLevel: 2), // Murloc Warleader
        BattlegroundMinion(cardId: "EX1_509", techLevel: 1), // Murloc Tidecaller
        BattlegroundMinion(cardId: "EX1_531", techLevel: 1), // Scavenging Hyena
        BattlegroundMinion(cardId: "EX1_534", techLevel: 4), // Savannah Highmane
        BattlegroundMinion(cardId: "EX1_556", techLevel: 2), // Harvest Golem
        BattlegroundMinion(cardId: "EX1_577", techLevel: 3), // The Beast
        BattlegroundMinion(cardId: "FP1_010", techLevel: 6), // Maexxna
        BattlegroundMinion(cardId: "FP1_024", techLevel: 2), // Unstable Ghoul
        BattlegroundMinion(cardId: "FP1_031", techLevel: 5), // Baron Rivendare
        BattlegroundMinion(cardId: "GVG_021", techLevel: 5), // Mal'Ganis
        BattlegroundMinion(cardId: "GVG_027", techLevel: 4), // Iron Sensei
        BattlegroundMinion(cardId: "GVG_048", techLevel: 2), // Metaltooth Leaper
        BattlegroundMinion(cardId: "GVG_055", techLevel: 3), // Screwjank Clunker
        BattlegroundMinion(cardId: "GVG_100", techLevel: 4), // Floating Watcher
        BattlegroundMinion(cardId: "GVG_106", techLevel: 5), // Junkbot
        BattlegroundMinion(cardId: "GVG_113", techLevel: 6), // Foe Reaper 4000
        BattlegroundMinion(cardId: "ICC_029", techLevel: 4), // Cobalt Scalebane
        BattlegroundMinion(cardId: "ICC_038", techLevel: 1), // Righteous Protector
        BattlegroundMinion(cardId: "ICC_807", techLevel: 5), // Strongshell Scavenger
        BattlegroundMinion(cardId: "ICC_858", techLevel: 4), // Bolvar, Fireblood
        BattlegroundMinion(cardId: "KAR_005", techLevel: 2), // Kindly Grandmother
        BattlegroundMinion(cardId: "LOE_077", techLevel: 5), // Brann Bronzebeard
        BattlegroundMinion(cardId: "LOOT_013", techLevel: 1), // Vulgar Homunculus
        BattlegroundMinion(cardId: "LOOT_078", techLevel: 4), // Cave Hydra
        BattlegroundMinion(cardId: "LOOT_368", techLevel: 5), // Voidlord
        BattlegroundMinion(cardId: "NEW1_027", techLevel: 2), // Southsea Captain
        BattlegroundMinion(cardId: "OG_216", techLevel: 3), // Infested Wolf
        BattlegroundMinion(cardId: "OG_221", techLevel: 1), // Selfless Hero
        BattlegroundMinion(cardId: "OG_256", techLevel: 2), // Spawn of N'Zoth
        BattlegroundMinion(cardId: "TRL_232", techLevel: 5), // Ironhide Direhorn
        BattlegroundMinion(cardId: "ULD_217", techLevel: 1), // Micro Mummy
        BattlegroundMinion(cardId: "UNG_073", techLevel: 1), // Rockpool Hunter
        BattlegroundMinion(cardId: "YOD_026", techLevel: 1) // Fiendish Servant
    ]
    
    init() {
        super.init(frame: NSRect.zero)
        self.orientation = .vertical
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.orientation = .vertical
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.orientation = .vertical
    }
    
    func score(race: Race?) -> Int {
        guard let r = race else {
            return 0
        }
        return Race.allCases.firstIndex { $0 == r } ?? 0
    }
    
    func setTier(tier: Int) {
        let availableRaces = AppDelegate.instance().coreManager.game.availableRaces
        var cardBars: [CardBar] = battlegroundsMinions.filter {
            let ktCard = Cards.by(cardId: $0.cardId)
            guard let card = ktCard else {
                return false
            }
            let race = card.race
            return ($0.techLevel == tier && (race == .invalid || (availableRaces?.firstIndex(of: race) != nil)))
        }.map {
            let card = Card()

            let ktCard = Cards.by(cardId: $0.cardId)!
            card.cost = -1
            card.id = $0.cardId
            card.name = ktCard.name
            card.race = ktCard.race
            card.count = 1
            card.rarity = ktCard.rarity

            let cardBar = CardBar.factory()
            cardBar.card = card
            return cardBar
        }
        
        var cardBar = CardBar.factory()

        let size = NSSize(width: cardBar.imageRect.width, height: cardBar.imageRect.height)
        let blackImage = NSImage(color: NSColor(red: 35/255.0, green: 39/255.0, blue: 42/255.0, alpha: 1.0), size: size)

        cardBar.playerName = "Neutral"
        let race = Race(rawValue: "invalid")
        cardBar.playerRace = race
        cardBar.backgroundImage = blackImage
        cardBars.append(cardBar)
        for i in 0..<availableRaces!.count {
            let race: String = availableRaces![i].rawValue
            cardBar = CardBar.factory()
            cardBar.playerName = NSLocalizedString(race, comment: "")
            let cardRace = Race(rawValue: race)
            cardBar.playerRace = cardRace
            cardBar.backgroundImage = blackImage
            cardBars.append(cardBar)
        }
        cardBars = cardBars.sorted(by: {(a: CardBar, b: CardBar) -> Bool in
            var raceA: String
            var nameA: String
            var isTitleA: Int
            if a.card?.race != nil {
                raceA = a.card!.race.rawValue
                nameA = a.card!.name
                isTitleA = 1
            } else {
                raceA = a.playerRace!.rawValue
                nameA = a.playerName!
                isTitleA = 0
            }
            if raceA == "invalid" {
                raceA = "neutral"
            }
            var raceB: String
            var nameB: String
            var isTitleB: Int
            if b.card?.race != nil {
                raceB = b.card!.race.rawValue
                nameB = b.card!.name
                isTitleB = 1
            } else {
                raceB = b.playerRace!.rawValue
                nameB = b.playerName!
                isTitleB = 0
            }
            if raceB == "invalid" {
                raceB = "neutral"
            }
            return (raceA, isTitleA, nameA) > (raceB, isTitleB, nameB)
        })
        while self.subviews.count > 0 {
            self.subviews[0].removeFromSuperviewWithoutNeedingDisplay()
        }
        
        var cardHeight: CGFloat
        switch Settings.cardSize {
        case .tiny: cardHeight = CGFloat(kTinyRowHeight)
        case .small: cardHeight = CGFloat(kSmallRowHeight)
        case .medium: cardHeight = CGFloat(kMediumRowHeight)
        case .huge: cardHeight = CGFloat(kHighRowHeight)
        case .big: cardHeight = CGFloat(kRowHeight)
        }

        var totalHeight = CGFloat(cardBars.count) * cardHeight
        if totalHeight > self.frame.height {
            totalHeight = self.frame.height
            cardHeight = totalHeight / CGFloat(cardBars.count)
        }
        
        for i in 0...(cardBars.count - 1) {
            let y = CGFloat(i) * cardHeight + self.frame.height - totalHeight
            let cardBar = cardBars[i]
            cardBar.frame = NSRect(x: 0, y: y, width: self.frame.width, height: cardHeight)
            self.addSubview(cardBar)
        }
    }
}
