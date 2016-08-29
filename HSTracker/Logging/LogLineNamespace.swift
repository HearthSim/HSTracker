//
//  LogLineNamespace.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum LogLineNamespace: String {
    case Achievements, AdTracking, All, Arena, Asset, BIReport, BattleNet, Becca, Ben, Bob, Brian,
    BugReporter, Cameron, CardbackMgr, ChangedCards, ClientRequestManager, ConfigFile, Crafting,
    DbfXml, DeckHelper, DeckRuleset, DeckTray, Derek, DeviceEmulation, Downloader, EndOfGame,
    EventTiming, FaceDownCard, FullScreenFX, GameMgr, Graphics, Hand, HealthyGaming, Henry,
    InnKeepersSpecial, JMac, Jay, Josh, Kyle, LoadingScreen, Mike, MikeH, MissingAssets, Net,
    Packet, Party, PlayErrors, Power, RAF, Rachelle, Reset, Robin, Ryan, Sound, Spectator, Store,
    UpdateManager, UserAttention, Yim, Zone
    
    static func usedValues() -> [LogLineNamespace] {
        return [.Power, .Net, .Asset, .Bob, .Rachelle, .Arena, .LoadingScreen, .FullScreenFX]
    }
    
    static func allValues() -> [LogLineNamespace] {
        return [.Achievements, .AdTracking, .All, .Arena, .Asset, .BIReport, .BattleNet, .Becca,
                .Ben, .Bob, .Brian, .BugReporter, .Cameron, .CardbackMgr, .ChangedCards,
                .ClientRequestManager, .ConfigFile, .Crafting, .DbfXml, .DeckHelper, .DeckRuleset,
                .DeckTray, .Derek, .DeviceEmulation, .Downloader, .EndOfGame, .EventTiming,
                .FaceDownCard, .FullScreenFX, .GameMgr, .Graphics, .Hand, .HealthyGaming, .Henry,
                .InnKeepersSpecial, .JMac, .Jay, .Josh, .Kyle, .LoadingScreen, .Mike, .MikeH,
                .MissingAssets, .Net, .Packet, .Party, .PlayErrors, .Power, .RAF, .Rachelle, .Reset,
                .Robin, .Ryan, .Sound, .Spectator, .Store, .UpdateManager, .UserAttention,
                .Yim, .Zone]
    }
}