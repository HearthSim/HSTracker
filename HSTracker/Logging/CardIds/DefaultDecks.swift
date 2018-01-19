//
//  DefaultDecks.swift
//  HSTracker
//
//  Created by Fehervari, Istvan on 1/13/18.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation

struct DefaultDecks {
    
    struct DungeonRun {
        
        static func deck(for playerClass: CardClass) -> [Card] {
            switch playerClass {
            case .rogue:
                return DungeonRun.rogue
            case .druid:
                return DungeonRun.druid
            case .hunter:
                return DungeonRun.hunter
            case .mage:
                return DungeonRun.mage
            case .paladin:
                return DungeonRun.paladin
            case .shaman:
                return DungeonRun.shaman
            case .priest:
                return DungeonRun.priest
            case .warlock:
                return DungeonRun.warlock
            case .warrior:
                return DungeonRun.warrior
            default:
                logger.error("Failed to select dungeon run starter deck: \(playerClass) is not supported")
                return []
            }
        }
        
        static var rogue: [Card] = {
           return [
            Cards.by(cardId: CardIds.Collectible.Rogue.Backstab)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.DeadlyPoison)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.PitSnake)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.SinisterStrike)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.GilblinStalker)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.UndercityHuckster)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.Si7Agent)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.UnearthedRaptor)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.Assassinate)!,
            Cards.by(cardId: CardIds.Collectible.Rogue.Vanish)!
            ]
        }()
        
        static var warrior: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Warrior.Warbot)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.AmaniBerserker)!,
                Cards.by(cardId: CardIds.Collectible.Warrior.CruelTaskmaster)!,
                Cards.by(cardId: CardIds.Collectible.Warrior.HeroicStrike)!,
                Cards.by(cardId: CardIds.Collectible.Warrior.Bash)!,
                Cards.by(cardId: CardIds.Collectible.Warrior.FieryWarAxe)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.HiredGun)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.RagingWorgen)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.DreadCorsair)!,
                Cards.by(cardId: CardIds.Collectible.Warrior.Brawl)!
            ]
        }()
        
        static var shaman: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Shaman.AirElemental)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.LightningBolt)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.FlametongueTotem)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.MurlocTidehunter)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.StormforgedAxe)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.LightningStorm)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.UnboundElemental)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.DefenderOfArgus)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.Hex)!,
                Cards.by(cardId: CardIds.Collectible.Shaman.FireElemental)!
            ]
        }()
        
        static var paladin: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Paladin.BlessingOfMight)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.GoldshireFootman)!,
                Cards.by(cardId: CardIds.Collectible.Paladin.NobleSacrifice)!,
                Cards.by(cardId: CardIds.Collectible.Paladin.ArgentProtector)!,
                Cards.by(cardId: CardIds.Collectible.Paladin.Equality)!,
                Cards.by(cardId: CardIds.Collectible.Paladin.HolyLight)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.EarthenRingFarseer)!,
                Cards.by(cardId: CardIds.Collectible.Paladin.Consecration)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.StormwindKnight)!,
                Cards.by(cardId: CardIds.Collectible.Paladin.TruesilverChampion)!
            ]
        }()
        
        static var hunter: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Hunter.HuntersMark)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.StonetuskBoar)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.DireWolfAlpha)!,
                Cards.by(cardId: CardIds.Collectible.Hunter.ExplosiveTrap)!,
                Cards.by(cardId: CardIds.Collectible.Hunter.AnimalCompanion)!,
                Cards.by(cardId: CardIds.Collectible.Hunter.DeadlyShot)!,
                Cards.by(cardId: CardIds.Collectible.Hunter.EaglehornBow)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.JunglePanther)!,
                Cards.by(cardId: CardIds.Collectible.Hunter.UnleashTheHounds)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.OasisSnapjaw)!
            ]
        }()
        
        static var druid: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Druid.EnchantedRaven)!,
                Cards.by(cardId: CardIds.Collectible.Druid.PowerOfTheWild)!,
                Cards.by(cardId: CardIds.Collectible.Druid.TortollanForager)!,
                Cards.by(cardId: CardIds.Collectible.Druid.MountedRaptor)!,
                Cards.by(cardId: CardIds.Collectible.Druid.Mulch)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.ShadeOfNaxxramas)!,
                Cards.by(cardId: CardIds.Collectible.Druid.KeeperOfTheGrove)!,
                Cards.by(cardId: CardIds.Collectible.Druid.SavageCombatant)!,
                Cards.by(cardId: CardIds.Collectible.Druid.Swipe)!,
                Cards.by(cardId: CardIds.Collectible.Druid.DruidOfTheClaw)!
            ]
        }()

        static var warlock: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Warlock.Corruption)!,
                Cards.by(cardId: CardIds.Collectible.Warlock.MortalCoil)!,
                Cards.by(cardId: CardIds.Collectible.Warlock.Voidwalker)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.KnifeJuggler)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.SunfuryProtector)!,
                Cards.by(cardId: CardIds.Collectible.Warlock.DrainLife)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.ImpMaster)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.DarkIronDwarf)!,
                Cards.by(cardId: CardIds.Collectible.Warlock.Hellfire)!,
                Cards.by(cardId: CardIds.Collectible.Warlock.Doomguard)!
            ]
        }()

        static var mage: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Mage.ArcaneMissiles)!,
                Cards.by(cardId: CardIds.Collectible.Mage.ManaWyrm)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.Doomsayer)!,
                Cards.by(cardId: CardIds.Collectible.Mage.Frostbolt)!,
                Cards.by(cardId: CardIds.Collectible.Mage.SorcerersApprentice)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.EarthenRingFarseer)!,
                Cards.by(cardId: CardIds.Collectible.Mage.IceBarrier)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.ChillwindYeti)!,
                Cards.by(cardId: CardIds.Collectible.Mage.Fireball)!,
                Cards.by(cardId: CardIds.Collectible.Mage.Blizzard)!
            ]
        }()
        
        static var priest: [Card] = {
            return [
                Cards.by(cardId: CardIds.Collectible.Priest.HolySmite)!,
                Cards.by(cardId: CardIds.Collectible.Priest.NorthshireCleric)!,
                Cards.by(cardId: CardIds.Collectible.Priest.PotionOfMadness)!,
                Cards.by(cardId: CardIds.Collectible.Priest.MindBlast)!,
                Cards.by(cardId: CardIds.Collectible.Priest.ShadowWordPain)!,
                Cards.by(cardId: CardIds.Collectible.Priest.DarkCultist)!,
                Cards.by(cardId: CardIds.Collectible.Priest.AuchenaiSoulpriest)!,
                Cards.by(cardId: CardIds.Collectible.Priest.Lightspawn)!,
                Cards.by(cardId: CardIds.Collectible.Neutral.FaerieDragon)!,
                Cards.by(cardId: CardIds.Collectible.Priest.HolyNova)!
            ]
        }()
    }
}
