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
        
        static func getDefaultDeck(playerClass: CardClass, set: CardSet, shrineCardId: String? = nil) -> Deck? {
            let cards = getCards(playerClass: playerClass, set: set, shrineCardId: shrineCardId)
            if cards == nil {
                return nil
            }
            return getDeck(playerClass: playerClass, set: set, isPVPDR: false, cards: cards?.compactMap({ x in Cards.by(cardId: x) }))
        }

        static func getDeckFromDbfIds(playerClass: CardClass, set: CardSet, isPVPDR: Bool, dbfIds: [Int]?) -> Deck? {
            return getDeck(playerClass: playerClass, set: set, isPVPDR: isPVPDR, cards: dbfIds?.compactMap({ x in Cards.by(dbfId: x) }))
        }
        
        static func getDeck(playerClass: CardClass, set: CardSet, isPVPDR: Bool, cards: [Card]?) -> Deck? {
            guard let cards = cards else {
                return nil
            }
            let deck = Deck()
            deck.tmpCards = cards
            deck.playerClass = playerClass
            deck.isDuels = isPVPDR
            deck.isDungeon = !isPVPDR
            deck.lastEdited = Date()
            
            let template = getDeckTemplate(set: set)
            
            deck.name = Helper.parseDeckNameTemplate(template: template, deck: deck)
            return deck
        }

        static func getDeckTemplate(set: CardSet) -> String {
            switch set {
            case CardSet.lootapalooza:
                return Settings.importDungeonTemplate
            case CardSet.gilneas:
                return Settings.importMonsterHuntTemplate
            case CardSet.troll:
                return Settings.importRumbleRunTemplate
            case CardSet.dalaran:
                return Settings.importDalaranHeistTemplate
            case CardSet.uldum:
                return Settings.importTombsOfTerrorTemplate
            case CardSet.darkmoon_faire:
                return Settings.importDuelsTemplate
            default:
                return "New Deck {Date dd-MM HH:mm}"
            }
        }
        
        static func getCards(playerClass: CardClass, set: CardSet, shrineCardId: String? = nil) -> [String]? {
            switch set {
            case CardSet.lootapalooza:
                switch playerClass {
                // TODO: Add Demon Hunter
                case .rogue:
                    return LootDefaultDecks.rogue
                case .warrior:
                   return LootDefaultDecks.warrior
                case .shaman:
                   return LootDefaultDecks.shaman
                case .paladin:
                   return LootDefaultDecks.paladin
                case .hunter:
                   return LootDefaultDecks.hunter
                case .druid:
                   return LootDefaultDecks.druid
                case .warlock:
                   return LootDefaultDecks.warlock
                case .mage:
                   return LootDefaultDecks.mage
                case .priest:
                   return LootDefaultDecks.priest
                default:
                    return nil
                }
            case CardSet.gilneas:
                switch playerClass {
                    // Todo: Add Demon Hunter
                case .rogue:
                    return GilDefaultDecks.rogue
                case .warrior:
                    return GilDefaultDecks.warrior
                case .hunter:
                    return GilDefaultDecks.hunter
                case .mage:
                    return GilDefaultDecks.mage
                default:
                    return nil
                }
            case CardSet.troll:
                switch playerClass {
                // Todo: Add Demon Hunter
                case .rogue:
                    return TrlDefaultDecks.rogue.first(where: { x in x.contains(shrineCardId ?? "") })
                case .warrior:
                    return TrlDefaultDecks.warrior.first(where: { x in x.contains(shrineCardId ?? "") })
                case .shaman:
                    return TrlDefaultDecks.shaman.first(where: { x in x.contains(shrineCardId ?? "") })
                case .paladin:
                    return TrlDefaultDecks.paladin.first(where: { x in x.contains(shrineCardId ?? "") })
                case .hunter:
                    return TrlDefaultDecks.hunter.first(where: { x in x.contains(shrineCardId ?? "") })
                case .druid:
                    return TrlDefaultDecks.druid.first(where: { x in x.contains(shrineCardId ?? "") })
                case .warlock:
                    return TrlDefaultDecks.warlock.first(where: { x in x.contains(shrineCardId ?? "") })
                case .mage:
                    return TrlDefaultDecks.mage.first(where: { x in x.contains(shrineCardId ?? "") })
                case .priest:
                    return TrlDefaultDecks.priest.first(where: { x in x.contains(shrineCardId ?? "") })
                default:
                    return nil
                }
            default:
                return nil
            }
        }

        static func getUldumHeroPlayerClass(playerClass: CardClass) -> CardClass {
            switch playerClass {
            case CardClass.mage, CardClass.rogue:
                return CardClass.mage
            case CardClass.paladin, CardClass.shaman:
                return CardClass.paladin
            case CardClass.druid, CardClass.priest:
                return CardClass.druid
            case CardClass.hunter, CardClass.warrior:
                return CardClass.hunter
            default:
                return CardClass.invalid
            }
        }
        
        static func isDungeonBoss(_ cardId: String?) -> Bool {
            guard let cardId else {
                return false
            }
            return (cardId.contains("LOOT") || cardId.contains("GIL") || cardId.contains("TRL")) && cardId.contains("BOSS")
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
    
    struct LootDefaultDecks {
        static let rogue = [ CardIds.Collectible.Rogue.Backstab,
                             CardIds.Collectible.Rogue.DeadlyPoison,
                             CardIds.Collectible.Rogue.PitSnake,
                             CardIds.Collectible.Rogue.SinisterStrike,
                             CardIds.Collectible.Neutral.GilblinStalker,
                             CardIds.Collectible.Rogue.UndercityHuckster,
                             CardIds.Collectible.Rogue.Si7Agent,
                             CardIds.Collectible.Rogue.UnearthedRaptor,
                             CardIds.Collectible.Rogue.Assassinate,
                             CardIds.Collectible.Rogue.Vanish ]
        
        static let warrior = [ CardIds.Collectible.Warrior.Warbot,
                               CardIds.Collectible.Neutral.AmaniBerserker,
                               CardIds.Collectible.Warrior.CruelTaskmaster,
                               CardIds.Collectible.Warrior.HeroicStrike,
                               CardIds.Collectible.Warrior.Bash,
                               CardIds.Collectible.Warrior.FieryWarAxe,
                               CardIds.Collectible.Neutral.HiredGun,
                               CardIds.Collectible.Neutral.RagingWorgen,
                               CardIds.Collectible.Neutral.DreadCorsair,
                               CardIds.Collectible.Warrior.Brawl ]

        static let shaman = [ CardIds.Collectible.Shaman.AirElemental,
                              CardIds.Collectible.Shaman.LightningBolt,
                              CardIds.Collectible.Shaman.FlametongueTotem,
                              CardIds.Collectible.Neutral.MurlocTidehunter,
                              CardIds.Collectible.Shaman.StormforgedAxe,
                              CardIds.Collectible.Shaman.LightningStorm,
                              CardIds.Collectible.Shaman.UnboundElemental,
                              CardIds.Collectible.Neutral.DefenderOfArgus,
                              CardIds.Collectible.Shaman.Hex,
                              CardIds.Collectible.Shaman.FireElemental ]

        static let paladin = [ CardIds.Collectible.Paladin.BlessingOfMight,
                               CardIds.Collectible.Neutral.GoldshireFootman,
                               CardIds.Collectible.Paladin.NobleSacrifice,
                               CardIds.Collectible.Paladin.ArgentProtector,
                               CardIds.Collectible.Paladin.Equality,
                               CardIds.Collectible.Paladin.HolyLight,
                               CardIds.Collectible.Neutral.EarthenRingFarseer,
                               CardIds.Collectible.Paladin.Consecration,
                               CardIds.Collectible.Neutral.StormwindKnight,
                               CardIds.Collectible.Paladin.TruesilverChampion ]

        static let hunter = [ CardIds.Collectible.Hunter.HuntersMark,
                              CardIds.Collectible.Neutral.StonetuskBoar,
                              CardIds.Collectible.Neutral.DireWolfAlpha,
                              CardIds.Collectible.Hunter.ExplosiveTrap,
                              CardIds.Collectible.Hunter.AnimalCompanion,
                              CardIds.Collectible.Hunter.DeadlyShot,
                              CardIds.Collectible.Hunter.EaglehornBow,
                              CardIds.Collectible.Neutral.JunglePanther,
                              CardIds.Collectible.Hunter.UnleashTheHounds,
                              CardIds.Collectible.Neutral.OasisSnapjaw ]

        static let druid = [ CardIds.Collectible.Druid.EnchantedRaven,
                             CardIds.Collectible.Druid.PowerOfTheWild,
                             CardIds.Collectible.Druid.TortollanForager,
                             CardIds.Collectible.Druid.MountedRaptor,
                             CardIds.Collectible.Druid.Mulch,
                             CardIds.Collectible.Neutral.ShadeOfNaxxramas,
                             CardIds.Collectible.Druid.KeeperOfTheGrove,
                             CardIds.Collectible.Druid.SavageCombatant,
                             CardIds.Collectible.Druid.Swipe,
                             CardIds.Collectible.Druid.DruidOfTheClaw ]

        static let warlock = [ CardIds.Collectible.Warlock.Corruption,
                               CardIds.Collectible.Warlock.MortalCoil,
                               CardIds.Collectible.Warlock.Voidwalker,
                               CardIds.Collectible.Neutral.KnifeJuggler,
                               CardIds.Collectible.Neutral.SunfuryProtector,
                               CardIds.Collectible.Warlock.DrainLife,
                               CardIds.Collectible.Neutral.ImpMaster,
                               CardIds.Collectible.Neutral.DarkIronDwarf,
                               CardIds.Collectible.Warlock.Hellfire,
                               CardIds.Collectible.Warlock.Doomguard ]

        static let mage = [ CardIds.Collectible.Neutral.ArcaneAnomaly,
                            CardIds.Collectible.Mage.ArcaneMissiles,
                            CardIds.Collectible.Neutral.Doomsayer,
                            CardIds.Collectible.Mage.Frostbolt,
                            CardIds.Collectible.Mage.SorcerersApprentice,
                            CardIds.Collectible.Neutral.EarthenRingFarseer,
                            CardIds.Collectible.Mage.IceBarrier,
                            CardIds.Collectible.Neutral.ChillwindYeti,
                            CardIds.Collectible.Mage.Fireball,
                            CardIds.Collectible.Mage.Blizzard ]

        static let priest = [ CardIds.Collectible.Priest.HolySmite,
                              CardIds.Collectible.Priest.NorthshireCleric,
                              CardIds.Collectible.Priest.PotionOfMadness,
                              CardIds.Collectible.Neutral.FaerieDragon,
                              CardIds.Collectible.Priest.MindBlast,
                              CardIds.Collectible.Priest.ShadowWordPain,
                              CardIds.Collectible.Priest.DarkCultist,
                              CardIds.Collectible.Priest.AuchenaiSoulpriest,
                              CardIds.Collectible.Priest.Lightspawn,
                              CardIds.Collectible.Priest.HolyNova ]
    }
    
    struct GilDefaultDecks {
        static let rogue = [ CardIds.Collectible.Neutral.ElvenArcher,
                             CardIds.Collectible.Rogue.SinisterStrike,
                             CardIds.Collectible.Neutral.WorgenInfiltrator,
                             CardIds.Collectible.Neutral.BloodsailRaider,
                             CardIds.Collectible.Hunter.Glaivezooka,
                             CardIds.Collectible.Hunter.SnakeTrap,
                             CardIds.Collectible.Rogue.BlinkFox,
                             CardIds.Collectible.Rogue.FanOfKnives,
                             CardIds.Collectible.Neutral.HiredGun,
                             CardIds.Collectible.Rogue.Si7Agent ]

        static let warrior = [ CardIds.Collectible.Neutral.AbusiveSergeant,
                               CardIds.NonCollectible.Neutral.ExtraPowder,
                               CardIds.Collectible.Neutral.LowlySquire,
                               CardIds.Collectible.Neutral.AmaniBerserker,
                               CardIds.Collectible.Warrior.CruelTaskmaster,
                               CardIds.Collectible.Warrior.RedbandWasp,
                               CardIds.Collectible.Warrior.Bash,
                               CardIds.Collectible.Warrior.FierceMonkey,
                               CardIds.Collectible.Warrior.KingsDefender,
                               CardIds.Collectible.Warrior.BloodhoofBrave ]

        static let hunter = [ CardIds.Collectible.Hunter.FieryBat,
                              CardIds.Collectible.Hunter.OnTheHunt,
                              CardIds.Collectible.Neutral.SwampLeech,
                              CardIds.Collectible.Hunter.CracklingRazormaw,
                              CardIds.Collectible.Hunter.Toxmonger_HuntingMastiffToken,
                              CardIds.Collectible.Hunter.ForlornStalker,
                              CardIds.Collectible.Hunter.KillCommand,
                              CardIds.Collectible.Hunter.UnleashTheHounds,
                              CardIds.Collectible.Hunter.Houndmaster,
                              CardIds.Collectible.Neutral.SwiftMessenger ]

        static let mage = [ CardIds.Collectible.Mage.BabblingBook,
                            CardIds.Collectible.Neutral.MadBomber,
                            CardIds.Collectible.Mage.PrimordialGlyph,
                            CardIds.Collectible.Mage.UnstablePortal,
                            CardIds.Collectible.Mage.Cinderstorm,
                            CardIds.Collectible.Mage.Flamewaker,
                            CardIds.Collectible.Mage.Spellslinger,
                            CardIds.Collectible.Neutral.TinkmasterOverspark,
                            CardIds.Collectible.Mage.WaterElemental,
                            CardIds.Collectible.Neutral.Blingtron3000 ]
    }
    
    struct TrlDefaultDecks {
        static let rogue = [ [ CardIds.NonCollectible.Rogue.BottledTerror,
                               CardIds.Collectible.Rogue.Buccaneer,
                               CardIds.Collectible.Rogue.ColdBlood,
                               CardIds.Collectible.Rogue.DefiasRingleader,
                               CardIds.Collectible.Rogue.ShadowSensei,
                               CardIds.Collectible.Neutral.AbusiveSergeant,
                               CardIds.Collectible.Neutral.SouthseaDeckhand,
                               CardIds.Collectible.Neutral.CaptainsParrot,
                               CardIds.Collectible.Neutral.SharkfinFan,
                               CardIds.Collectible.Neutral.ShipsCannon,
                               CardIds.Collectible.Neutral.HenchClanThug ],
                             [ CardIds.NonCollectible.Rogue.TreasureFromBelow,
                               CardIds.Collectible.Rogue.Preparation,
                               CardIds.Collectible.Rogue.CounterfeitCoin,
                               CardIds.Collectible.Rogue.Backstab,
                               CardIds.Collectible.Rogue.Conceal,
                               CardIds.Collectible.Rogue.UndercityValiant,
                               CardIds.Collectible.Rogue.Betrayal,
                               CardIds.Collectible.Rogue.ObsidianShard,
                               CardIds.Collectible.Neutral.SmallTimeBuccaneer,
                               CardIds.Collectible.Neutral.SouthseaDeckhand,
                               CardIds.Collectible.Neutral.BloodsailRaider ],
                             [ CardIds.NonCollectible.Rogue.PiratesMark,
                               CardIds.Collectible.Rogue.Backstab,
                               CardIds.Collectible.Rogue.CounterfeitCoin,
                               CardIds.Collectible.Neutral.ArcaneAnomaly,
                               CardIds.Collectible.Rogue.SinisterStrike,
                               CardIds.Collectible.Rogue.Betrayal,
                               CardIds.Collectible.Neutral.KoboldGeomancer,
                               CardIds.Collectible.Neutral.Spellzerker,
                               CardIds.Collectible.Rogue.FanOfKnives,
                               CardIds.Collectible.Rogue.AcademicEspionage,
                               CardIds.Collectible.Rogue.TombPillager ] ]

        static let warrior = [ [ CardIds.NonCollectible.Warrior.AkalisChampion,
                                 CardIds.Collectible.Warrior.EterniumRover,
                                 CardIds.Collectible.Warrior.Armorsmith,
                                 CardIds.Collectible.Warrior.DrywhiskerArmorer,
                                 CardIds.Collectible.Warrior.FieryWarAxe,
                                 CardIds.Collectible.Warrior.MountainfireArmor,
                                 CardIds.Collectible.Warrior.EmberscaleDrake,
                                 CardIds.Collectible.Neutral.Waterboy,
                                 CardIds.Collectible.Neutral.HiredGun,
                                 CardIds.Collectible.Neutral.HalfTimeScavenger,
                                 CardIds.Collectible.Neutral.DragonmawScorcher ],
                               [ CardIds.NonCollectible.Warrior.AkalisWarDrum,
                                 CardIds.Collectible.Warrior.DragonRoar,
                                 CardIds.Collectible.Neutral.FaerieDragon,
                                 CardIds.Collectible.Neutral.FiretreeWitchdoctor,
                                 CardIds.Collectible.Neutral.NetherspiteHistorian,
                                 CardIds.Collectible.Warrior.FieryWarAxe,
                                 CardIds.Collectible.Neutral.NightmareAmalgam,
                                 CardIds.Collectible.Neutral.EbonDragonsmith,
                                 CardIds.Collectible.Neutral.TwilightGuardian,
                                 CardIds.Collectible.Warrior.EmberscaleDrake,
                                 CardIds.Collectible.Neutral.BoneDrake ],
                               [ CardIds.NonCollectible.Warrior.AkalisHorn,
                                 CardIds.Collectible.Warrior.InnerRage,
                                 CardIds.Collectible.Warrior.NzothsFirstMate,
                                 CardIds.Collectible.Warrior.Warbot,
                                 CardIds.Collectible.Warrior.Execute,
                                 CardIds.Collectible.Warrior.Rampage,
                                 CardIds.Collectible.Warrior.CruelTaskmaster,
                                 CardIds.Collectible.Warrior.BloodhoofBrave,
                                 CardIds.Collectible.Neutral.AmaniBerserker,
                                 CardIds.Collectible.Neutral.Deathspeaker,
                                 CardIds.Collectible.Neutral.RagingWorgen ] ]

        static let shaman = [ [ CardIds.NonCollectible.Shaman.KragwasLure,
                                CardIds.Collectible.Shaman.ForkedLightning,
                                CardIds.Collectible.Shaman.StormforgedAxe,
                                CardIds.Collectible.Shaman.UnboundElemental,
                                CardIds.Collectible.Shaman.LightningStorm,
                                CardIds.Collectible.Shaman.JinyuWaterspeaker,
                                CardIds.Collectible.Shaman.FireguardDestroyer,
                                CardIds.Collectible.Neutral.MurlocRaider,
                                CardIds.Collectible.Neutral.DeadscaleKnight,
                                CardIds.Collectible.Neutral.HugeToad,
                                CardIds.Collectible.Neutral.TarCreeper ],
                              [ CardIds.NonCollectible.Shaman.TributeFromTheTides,
                                CardIds.Collectible.Shaman.BlazingInvocation,
                                CardIds.Collectible.Shaman.TotemicSmash,
                                CardIds.Collectible.Shaman.HotSpringGuardian,
                                CardIds.Collectible.Shaman.LightningStorm,
                                CardIds.Collectible.Shaman.FireElemental,
                                CardIds.Collectible.Neutral.EmeraldReaver,
                                CardIds.Collectible.Neutral.FireFly,
                                CardIds.Collectible.Neutral.BilefinTidehunter,
                                CardIds.Collectible.Neutral.BelligerentGnome,
                                CardIds.Collectible.Neutral.SaroniteChainGang ],
                              [ CardIds.NonCollectible.Shaman.KragwasGrace,
                                CardIds.Collectible.Shaman.Wartbringer,
                                CardIds.Collectible.Shaman.Crackle,
                                CardIds.Collectible.Shaman.LavaShock,
                                CardIds.Collectible.Shaman.MaelstromPortal,
                                CardIds.Collectible.Shaman.FarSight,
                                CardIds.Collectible.Shaman.FeralSpirit,
                                CardIds.Collectible.Shaman.CallInTheFinishers,
                                CardIds.Collectible.Shaman.RainOfToads,
                                CardIds.Collectible.Neutral.ManaAddict,
                                CardIds.Collectible.Neutral.BananaBuffoon ] ]

        static let paladin = [ [ CardIds.NonCollectible.Paladin.ShirvallahsProtection,
                                 CardIds.Collectible.Paladin.DivineStrength,
                                 CardIds.Collectible.Paladin.MeanstreetMarshal,
                                 CardIds.Collectible.Paladin.GrimestreetOutfitter,
                                 CardIds.Collectible.Paladin.ParagonOfLight,
                                 CardIds.Collectible.Paladin.FarrakiBattleaxe,
                                 CardIds.Collectible.Neutral.ElvenArcher,
                                 CardIds.Collectible.Neutral.InjuredKvaldir,
                                 CardIds.Collectible.Neutral.BelligerentGnome,
                                 CardIds.Collectible.Neutral.ArenaFanatic,
                                 CardIds.Collectible.Neutral.StormwindKnight ],
                               [ CardIds.NonCollectible.Paladin.ShirvallahsVengeance,
                                 CardIds.Collectible.Paladin.Bloodclaw,
                                 CardIds.Collectible.Paladin.FlashOfLight,
                                 CardIds.Collectible.Paladin.SealOfLight,
                                 CardIds.Collectible.Paladin.BenevolentDjinn,
                                 CardIds.Collectible.Paladin.TruesilverChampion,
                                 CardIds.Collectible.Paladin.ChillbladeChampion,
                                 CardIds.Collectible.Neutral.Crystallizer,
                                 CardIds.Collectible.Neutral.MadBomber,
                                 CardIds.Collectible.Neutral.HappyGhoul,
                                 CardIds.Collectible.Neutral.MadderBomber ],
                               [ CardIds.NonCollectible.Paladin.ShirvallahsGrace,
                                 CardIds.Collectible.Neutral.ArgentSquire,
                                 CardIds.Collectible.Paladin.DivineStrength,
                                 CardIds.Collectible.Paladin.HandOfProtection,
                                 CardIds.Collectible.Paladin.FlashOfLight,
                                 CardIds.Collectible.Paladin.PotionOfHeroism,
                                 CardIds.Collectible.Paladin.PrimalfinChampion,
                                 CardIds.Collectible.Neutral.BananaBuffoon,
                                 CardIds.Collectible.Paladin.SealOfChampions,
                                 CardIds.Collectible.Paladin.BlessingOfKings,
                                 CardIds.Collectible.Paladin.TruesilverChampion ] ]
        
        static let hunter = [ [ CardIds.NonCollectible.Hunter.HalazzisTrap,
                                CardIds.Collectible.Hunter.Candleshot,
                                CardIds.Collectible.Hunter.ArcaneShot,
                                CardIds.Collectible.Hunter.HuntersMark,
                                CardIds.Collectible.Hunter.SecretPlan,
                                CardIds.Collectible.Hunter.ExplosiveTrap,
                                CardIds.Collectible.Hunter.QuickShot,
                                CardIds.Collectible.Hunter.AnimalCompanion,
                                CardIds.Collectible.Hunter.BloodscalpStrategist,
                                CardIds.Collectible.Hunter.BaitedArrow,
                                CardIds.Collectible.Neutral.BurglyBully ],
                              [ CardIds.NonCollectible.Hunter.HalazzisHunt,
                                CardIds.Collectible.Hunter.HuntersMark,
                                CardIds.Collectible.Hunter.Alleycat,
                                CardIds.Collectible.Hunter.Springpaw,
                                CardIds.Collectible.Hunter.Glaivezooka,
                                CardIds.Collectible.Hunter.ScavengingHyena,
                                CardIds.Collectible.Hunter.AnimalCompanion,
                                CardIds.Collectible.Hunter.CaveHydra,
                                CardIds.Collectible.Hunter.Houndmaster,
                                CardIds.Collectible.Hunter.SavannahHighmane,
                                CardIds.Collectible.Neutral.DireWolfAlpha ],
                              [ CardIds.NonCollectible.Hunter.HalazzisGuise,
                                CardIds.Collectible.Hunter.JeweledMacaw,
                                CardIds.Collectible.Hunter.Springpaw,
                                CardIds.Collectible.Hunter.Webspinner,
                                CardIds.Collectible.Hunter.KillCommand,
                                CardIds.Collectible.Hunter.RatPack,
                                CardIds.Collectible.Hunter.BaitedArrow,
                                CardIds.Collectible.Neutral.DireWolfAlpha,
                                CardIds.Collectible.Neutral.SilverbackPatriarch,
                                CardIds.Collectible.Neutral.UntamedBeastmaster,
                                CardIds.Collectible.Neutral.OasisSnapjaw ] ]

        static let druid = [ [ CardIds.NonCollectible.Druid.GonksArmament,
                               CardIds.Collectible.Druid.ForbiddenAncient,
                               CardIds.Collectible.Druid.LesserJasperSpellstone,
                               CardIds.Collectible.Neutral.LowlySquire,
                               CardIds.Collectible.Neutral.Waterboy,
                               CardIds.Collectible.Druid.Wrath,
                               CardIds.Collectible.Druid.FerociousHowl,
                               CardIds.Collectible.Druid.GroveTender,
                               CardIds.Collectible.Neutral.HalfTimeScavenger,
                               CardIds.Collectible.Druid.IronwoodGolem,
                               CardIds.Collectible.Neutral.SnapjawShellfighter ],
                             [ CardIds.NonCollectible.Druid.GonksMark,
                               CardIds.Collectible.Druid.EnchantedRaven,
                               CardIds.Collectible.Druid.PowerOfTheWild,
                               CardIds.Collectible.Druid.WitchwoodApple,
                               CardIds.Collectible.Druid.MountedRaptor,
                               CardIds.Collectible.Druid.Swipe,
                               CardIds.Collectible.Neutral.WaxElemental,
                               CardIds.Collectible.Neutral.BloodfenRaptor,
                               CardIds.Collectible.Neutral.InfestedTauren,
                               CardIds.Collectible.Neutral.StormwindKnight,
                               CardIds.Collectible.Neutral.ArenaPatron ],
                             [ CardIds.NonCollectible.Druid.BondsOfBalance,
                               CardIds.Collectible.Druid.Pounce,
                               CardIds.Collectible.Druid.Claw,
                               CardIds.Collectible.Druid.EnchantedRaven,
                               CardIds.Collectible.Druid.PowerOfTheWild,
                               CardIds.Collectible.Druid.SavageStriker,
                               CardIds.Collectible.Druid.Gnash,
                               CardIds.Collectible.Druid.Bite,
                               CardIds.Collectible.Druid.SavageCombatant,
                               CardIds.Collectible.Neutral.Waterboy,
                               CardIds.Collectible.Neutral.SharkfinFan ] ]

        static let warlock = [ [ CardIds.NonCollectible.Warlock.BloodPact,
                                 CardIds.Collectible.Warlock.Voidwalker,
                                 CardIds.Collectible.Warlock.QueenOfPain,
                                 CardIds.Collectible.Warlock.Demonfire,
                                 CardIds.Collectible.Warlock.Duskbat,
                                 CardIds.Collectible.Warlock.ImpLosion,
                                 CardIds.Collectible.Warlock.LesserAmethystSpellstone,
                                 CardIds.Collectible.Warlock.FiendishCircle,
                                 CardIds.Collectible.Warlock.BaneOfDoom,
                                 CardIds.Collectible.Neutral.BananaBuffoon,
                                 CardIds.Collectible.Neutral.VioletIllusionist ],
                               [ CardIds.NonCollectible.Warlock.DarkReliquary,
                                 CardIds.Collectible.Warlock.Shriek,
                                 CardIds.Collectible.Warlock.Soulfire,
                                 CardIds.Collectible.Warlock.Voidwalker,
                                 CardIds.Collectible.Warlock.Felstalker,
                                 CardIds.Collectible.Warlock.DarkshireLibrarian,
                                 CardIds.Collectible.Warlock.RecklessDiretroll,
                                 CardIds.Collectible.Warlock.LakkariFelhound,
                                 CardIds.Collectible.Warlock.Soulwarden,
                                 CardIds.Collectible.Neutral.BelligerentGnome,
                                 CardIds.Collectible.Neutral.BananaBuffoon ],
                               [ CardIds.NonCollectible.Warlock.HireeksHunger,
                                 CardIds.Collectible.Warlock.FlameImp,
                                 CardIds.Collectible.Warlock.CallOfTheVoid,
                                 CardIds.Collectible.Warlock.SpiritBomb,
                                 CardIds.Collectible.Warlock.UnlicensedApothecary,
                                 CardIds.Collectible.Warlock.BloodWitch,
                                 CardIds.Collectible.Warlock.Hellfire,
                                 CardIds.Collectible.Neutral.KnifeJuggler,
                                 CardIds.Collectible.Neutral.Waterboy,
                                 CardIds.Collectible.Neutral.ImpMaster,
                                 CardIds.Collectible.Neutral.BlackwaldPixie ] ]

        static let mage = [ [ CardIds.NonCollectible.Mage.JanalaisMantle,
                              CardIds.Collectible.Mage.BabblingBook,
                              CardIds.Collectible.Mage.ArcaneExplosion,
                              CardIds.Collectible.Mage.ShimmeringTempest,
                              CardIds.Collectible.Mage.ExplosiveRunes,
                              CardIds.Collectible.Mage.Spellslinger,
                              CardIds.Collectible.Mage.GhastlyConjurer,
                              CardIds.Collectible.Mage.BlastWave,
                              CardIds.Collectible.Neutral.TournamentAttendee,
                              CardIds.Collectible.Neutral.Brainstormer,
                              CardIds.Collectible.Neutral.KabalChemist ],
                            [ CardIds.NonCollectible.Mage.JanalaisFlame,
                              CardIds.Collectible.Mage.ArcaneBlast,
                              CardIds.Collectible.Mage.FallenHero,
                              CardIds.Collectible.Mage.Cinderstorm,
                              CardIds.Collectible.Mage.DalaranAspirant,
                              CardIds.Collectible.Mage.Fireball,
                              CardIds.Collectible.Neutral.AcherusVeteran,
                              CardIds.Collectible.Neutral.FlameJuggler,
                              CardIds.Collectible.Neutral.BlackwaldPixie,
                              CardIds.Collectible.Neutral.DragonhawkRider,
                              CardIds.Collectible.Neutral.FirePlumePhoenix ],
                            [ CardIds.NonCollectible.Mage.JanalaisProgeny,
                              CardIds.Collectible.Mage.FreezingPotion,
                              CardIds.Collectible.Neutral.ArcaneAnomaly,
                              CardIds.Collectible.Mage.Frostbolt,
                              CardIds.Collectible.Mage.Snowchugger,
                              CardIds.Collectible.Neutral.VolatileElemental,
                              CardIds.Collectible.Neutral.HyldnirFrostrider,
                              CardIds.Collectible.Mage.ConeOfCold,
                              CardIds.Collectible.Neutral.IceCreamPeddler,
                              CardIds.Collectible.Mage.WaterElemental,
                              CardIds.Collectible.Neutral.FrostElemental ] ]

        static let priest = [ [ CardIds.NonCollectible.Priest.BwonsamdisSanctum,
                                CardIds.Collectible.Priest.CrystallineOracle,
                                CardIds.Collectible.Priest.SpiritLash,
                                CardIds.Collectible.Priest.MuseumCurator,
                                CardIds.Collectible.Priest.DeadRinger,
                                CardIds.Collectible.Priest.ShiftingShade,
                                CardIds.Collectible.Priest.TortollanShellraiser,
                                CardIds.Collectible.Neutral.MistressOfMixtures,
                                CardIds.Collectible.Neutral.HarvestGolem,
                                CardIds.Collectible.Neutral.ShallowGravedigger,
                                CardIds.Collectible.Neutral.TombLurker ],
                              [ CardIds.NonCollectible.Priest.BwonsamdisTome,
                                CardIds.Collectible.Priest.PsionicProbe,
                                CardIds.Collectible.Priest.PowerWordShield,
                                CardIds.Collectible.Priest.SpiritLash,
                                CardIds.Collectible.Priest.SandDrudge,
                                CardIds.Collectible.Priest.GildedGargoyle,
                                CardIds.Collectible.Priest.Mindgames,
                                CardIds.Collectible.Neutral.ArcaneAnomaly,
                                CardIds.Collectible.Neutral.ClockworkGnome,
                                CardIds.Collectible.Neutral.WildPyromancer,
                                CardIds.Collectible.Neutral.BananaBuffoon],
                              [ CardIds.NonCollectible.Priest.BwonsamdisCovenant,
                                CardIds.Collectible.Priest.CircleOfHealing,
                                CardIds.Collectible.Priest.Regenerate,
                                CardIds.Collectible.Priest.FlashHeal,
                                CardIds.Collectible.Neutral.InjuredKvaldir,
                                CardIds.Collectible.Priest.LightOfTheNaaru,
                                CardIds.Collectible.Neutral.VoodooDoctor,
                                CardIds.Collectible.Neutral.GadgetzanSocialite,
                                CardIds.Collectible.Neutral.Waterboy,
                                CardIds.Collectible.Neutral.EarthenRingFarseer,
                                CardIds.Collectible.Neutral.InjuredBlademaster ] ]
    }
}
