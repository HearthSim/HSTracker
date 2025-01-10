//
//  BattlegroundsCompsGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompsGuidesViewModel: ViewModel {
    lazy var _db = BattlegroundsDb()
    
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
    
    // private func getTierColor(_ tier: Int) -> CALayer
    
    @available(macOS 10.15.0, *)
    private func trySetTier7View() async {
        
    }
}
