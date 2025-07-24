//
//  BattlegroundsCompsGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompsGuidesViewModel: ViewModel {
    
    var comps: [BattlegroundsCompGuideViewModel]? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
        }
    }
    
    var compsByTier: [Int: TieredComps]? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("tier7FeatureVisibility")
            onPropertyChanged("baseFeatureVisibility")
        }
    }
    
    @available(macOS 10.15.0, *)
    func getCompGuides() async -> [BattlegroundsCompGuideViewModel]? {
        let compsData = await HSReplayAPI.getCompsGuides(gameLanguage: Settings.hearthstone_language)
        let viewModel = compsData.sorted(by: { (a, b) in a.name < b.name }).compactMap({ comp in BattlegroundsCompGuideViewModel(comp) })
        return viewModel
    }
    
    var selectedComp: BattlegroundsCompGuideViewModel? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("isCompSelected")
        }
    }
    
    var isCompSelected: Bool {
        return selectedComp != nil
    }
    
    private let _updateCompGuidesSemaphore = DispatchSemaphore(value: 1)
    
    @available(macOS 10.15.0, *)
    func update() async {
        if AppDelegate.instance().coreManager.game.spectator {
            await Task.sleep(milliseconds: 1500)
        }
        
        defer {
            _updateCompGuidesSemaphore.signal()
        }
        _updateCompGuidesSemaphore.wait()
        await updateCompsGuidesIfNeeded()
    }
    
    @available(macOS 10.15.0, *)
    private func updateCompsGuidesIfNeeded() async {
        compsByTier = nil
        
        // Ensures data was already fetched and no more API calls are needed
        if comps?.count ?? 0 > 0 {
            await trySetTier7View()
            return
        }

        await trySetCompsGuides()
    }
    
    @available(macOS 10.15.0, *)
    private func trySetCompsGuides() async {
        var battlegroundsCompGuides: [BattlegroundsCompGuideViewModel]?

#if(DEBUG)
        logger.debug("Fetching Battlegrounds Comp Guides...")
#endif

        battlegroundsCompGuides = await getCompGuides()

        if let battlegroundsCompGuides {
            comps = battlegroundsCompGuides

            await trySetTier7View()
        }
    }
    
    struct TieredComps: Equatable {
        var tierLetter: String?
        var tierColor: CALayer?
        var comps: [BattlegroundsCompGuideViewModel]?
    }
    
    private func getCompText(_ tier: Int) -> String {
        return switch tier {
        case 1:
            "S"
        case 2:
            "A"
        case 3:
            "B"
        case 4:
            "C"
        case 5:
            "D"
        default:
            "?"
        }
    }
    
    private func getTierColor(_ tier: Int) -> CALayer {
        func createLinearGradient(_ color1: NSColor, _ color2: NSColor) -> CALayer {
            let brush = CAGradientLayer()
            brush.startPoint = CGPoint(x: 0.0, y: 0.5)
            brush.endPoint = CGPoint(x: 1.0, y: 0.5)
            brush.colors = [ color1.cgColor, color2.cgColor ]
            return brush
        }
        return switch tier {
        case 1:
            createLinearGradient(NSColor.fromRgb(64, 138, 191), NSColor.fromRgb(56, 95, 122))
        case 2:
            createLinearGradient(NSColor.fromRgb(107, 160, 54), NSColor.fromRgb(88, 121, 55))
        case 3:
            createLinearGradient(NSColor.fromRgb(146, 160, 54), NSColor.fromRgb(104, 121, 55))
        case 4:
            createLinearGradient(NSColor.fromRgb(160, 124, 54), NSColor.fromRgb(121, 95, 55))
        case 5:
            createLinearGradient(NSColor.fromRgb(160, 72, 54), NSColor.fromRgb(121, 66, 55))
        default:
            createLinearGradient(NSColor.fromRgb(112, 112, 112), NSColor.fromRgb(64, 64, 64))
        }
    }
    
    @available(macOS 10.15.0, *)
    private func trySetTier7View() async {
        let game = AppDelegate.instance().coreManager.game
        let gameId = game.serverInfo?.gameHandle.intValue
        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
//        let userHasTrials = Tier7Trial.remainingTrials ?? 0 > 0

        if !userOwnsTier7 && gameId == nil {
            return
        }

//        if !userOwnsTier7 && !(userHasTrials || Tier7Trial.isTrialForCurrentGameActive(gameId)) {
//            return
//        }

        // Use a trial if we can
        var token: String?
        if !userOwnsTier7 {
            let acc = MirrorHelper.getAccountId()
            if let acc {
                token = await Tier7Trial.activate(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
                if !((game.gameEntity?[.step] ?? 0) <= Step.begin_mulligan.rawValue) && token == nil {
                    return
                }
                
                if token == nil {
                    return
                }
            }
        }
            
        let availableRaces = game.availableRaces
        
        // Filter compositions by core cards based on available races
        if let comps {
            var filteredComps = comps

            if let availableRaces {
                let currentRaces = availableRaces + [ .invalid ]
                let availableCards = BattlegroundsDbSingleton.instance.getCardsByRaces(currentRaces, false)
                let availableCardIds = Set<Int>(availableCards.compactMap { card in card.dbfId })
                filteredComps = comps.filter { comp in comp.coreCards.all { card in availableCardIds.contains(card.dbfId) } }
            }

            compsByTier = filteredComps.group({ comp in comp.compGuide.tier }).compactMapValues({ comps in TieredComps(tierLetter: getCompText(comps[0].compGuide.tier), tierColor: getTierColor(comps[0].compGuide.tier), comps: comps)})
        }
    }
    
    var tier7FeatureVisibility: Bool {
        return compsByTier != nil
    }
    var baseFeatureVisibility: Bool {
        return compsByTier == nil
    }
}
