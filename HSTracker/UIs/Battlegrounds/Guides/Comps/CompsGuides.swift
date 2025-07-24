//
//  CompsGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/13/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CompsGuides: NSView, NSCollectionViewDataSource {
    @IBOutlet var contentView: NSView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var collectionView: NSCollectionView!
    @IBOutlet var flowLayout: NSCollectionViewFlowLayout!
    
    @IBOutlet var compGuide: CompGuide!
    
    var viewModel = BattlegroundsCompsGuidesViewModel()
    
    private var tiers =  [Int]()
    private var compsByTier = [Int: BattlegroundsCompsGuidesViewModel.TieredComps]()
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
//        var _: CompsGuides = NibHelper.loadViewFromNib(Self.self, self)
        NibHelper.loadNib(Self.self, self)
        
        viewModel.propertyChanged = { name in
            DispatchQueue.main.async {
                self.update(name)
            }
        }
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentView.frame = self.bounds
        
        collectionView.wantsLayer = true
    }
    
    override func awakeFromNib() {
        collectionView.register(NSNib(nibNamed: "CompButton", bundle: nil), forItemWithIdentifier: compButtonItemIdentifier)
        collectionView.dataSource = self
    }
    
    func update() {
        if let compsByTier = viewModel.compsByTier {
            let keys = compsByTier.keys.sorted()
            
            tiers = keys
            self.compsByTier = compsByTier
            
            collectionView?.reloadData()
        }
    }
    
    func update(_ name: String?) {
        if name == "compsByTier" {
            update()
        }
    }
    
    func showComp(_ comp: BattlegroundsCompGuideViewModel) {
        compGuide.update(comp, self)
        compGuide.isHidden = false
        scrollView.isHidden = true
    }
    
    func back() {
        compGuide.isHidden = true
        scrollView.isHidden = false
    }
    
    // MARK: - Collection View
    let compButtonItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "compButtonItemIdentifier")
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return tiers.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < tiers.count else {
            return 0
        }
        return compsByTier[tiers[section]]?.comps?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard indexPath.section < tiers.count, let comps = compsByTier[tiers[indexPath.section]]?.comps, indexPath.item < comps.count else {
            return NSCollectionViewItem()
        }
        guard let item = collectionView.makeItem(withIdentifier: compButtonItemIdentifier, for: indexPath) as? CompButton else {
            return NSCollectionViewItem()
        }
        
        let comp = comps[indexPath.item]
        
        item.update(comp, self)

        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        guard let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CompGuideGroupHeader"), for: indexPath) as? CompGuideGroupHeader, let compsByTier = viewModel.compsByTier else {
            return NSView()
        }
        
        guard indexPath.section < tiers.count, let comp = compsByTier[tiers[indexPath.section]] else {
            return NSView()
        }

        view.update(comp.tierColor ?? CALayer(), comp.tierLetter ?? "-")
        return view
    }
}
