//
//  LogLineNamespace.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum LogLineNamespace: String {
    case achievements = "Achievements",
    adTracking = "AdTracking",
    all = "All",
    arena = "Arena",
    asset = "Asset",
    biReport = "BIReport",
    battleNet = "BattleNet",
    becca = "Becca",
    ben = "Ben",
    bob = "Bob",
    brian = "Brian",
    bugReporter = "BugReporter",
    cameron = "Cameron",
    cardbackMgr = "CardbackMgr",
    changedCards = "ChangedCards",
    clientRequestManager = "ClientRequestManager",
    configFile = "ConfigFile",
    crafting = "Crafting",
    dbfXml = "DbfXml",
    deckHelper = "DeckHelper",
    deckRuleset = "DeckRuleset",
    deckTray = "DeckTray",
    derek = "Derek",
    deviceEmulation = "DeviceEmulation",
    downloader = "Downloader",
    endOfGame = "EndOfGame",
    eventTiming = "EventTiming",
    faceDownCard = "FaceDownCard",
    fullScreenFX = "FullScreenFX",
    gameMgr = "GameMgr",
    graphics = "Graphics",
    hand = "Hand",
    healthyGaming = "HealthyGaming",
    henry = "Henry",
    innKeepersSpecial = "InnKeepersSpecial",
    jMac = "JMac",
    jay = "Jay",
    josh = "Josh",
    kyle = "Kyle",
    loadingScreen = "LoadingScreen",
    mike = "Mike",
    mikeH = "MikeH",
    missingAssets = "MissingAssets",
    net = "Net",
    packet = "Packet",
    party = "Party",
    playErrors = "PlayErrors",
    power = "Power",
    raf = "RAF",
    rachelle = "Rachelle",
    reset = "Reset",
    robin = "Robin",
    ryan = "Ryan",
    sound = "Sound",
    spectator = "Spectator",
    store = "Store",
    updateManager = "UpdateManager",
    userAttention = "UserAttention",
    yim = "Yim",
    zone = "Zone"
    
    static func usedValues() -> [LogLineNamespace] {
        return [.power, .rachelle, .arena, .loadingScreen]
    }
    
    static func allValues() -> [LogLineNamespace] {
        return [.achievements, .adTracking, .all, .arena, .asset, .biReport, .battleNet, .becca,
                .ben, .bob, .brian, .bugReporter, .cameron, .cardbackMgr, .changedCards,
                .clientRequestManager, .configFile, .crafting, .dbfXml, .deckHelper, .deckRuleset,
                .deckTray, .derek, .deviceEmulation, .downloader, .endOfGame, .eventTiming,
                .faceDownCard, .fullScreenFX, .gameMgr, .graphics, .hand, .healthyGaming, .henry,
                .innKeepersSpecial, .jMac, .jay, .josh, .kyle, .loadingScreen, .mike, .mikeH,
                .missingAssets, .net, .packet, .party, .playErrors, .power, .raf, .rachelle, .reset,
                .robin, .ryan, .sound, .spectator, .store, .updateManager, .userAttention,
                .yim, .zone]
    }
}
