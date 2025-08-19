//
//  GridCardImages.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/31/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class HiddenScroller: NSScroller {

    // @available(macOS 10.7, *)
    // let NSScroller tell NSScrollView that its own width is 0, so that it will not really occupy the drawing area.
    override class func scrollerWidth(for controlSize: ControlSize, scrollerStyle: Style) -> CGFloat {
        0
    }
}

class GridCardImages: OverWindowController, NSCollectionViewDataSource {
    @IBOutlet var collectionView: NSCollectionView!
    
    struct CardWithImage {
        var card: Card
        var loadingImageSource: String
    }
        
    var cards = SynchronizedArray<CardWithImage>()
    
    override func awakeFromNib() {
        collectionView.register(NSNib(nibNamed: "GridCardImageItem", bundle: nil), forItemWithIdentifier: cardImageItemIdentifier)
        collectionView.dataSource = self
        titleLabel.chunkFive()
    }
    
    private func getLoadingImagePath(_ card: Card) -> String {
        switch card.type {
        case .hero:
            return "loading_hero"
        case .minion:
            return "loading_minion"
        case .weapon:
            return "loading_weapon"
        default:
            return "loading_spell"
        }
    }
    
    private var _previousCards: [Card]?
    func setCardIdsFromCards(_ cards: [Card]?, _ maxGridHeight: Int? = nil) {
        guard let cards else {
            return
        }
        
        if let previousCards = _previousCards, previousCards.elementsEqual(cards) {
            if maxGridHeight != nil && maxGridHeight != _maxGridHeight || maxGridHeight == nil && gridHeight != _maxGridHeight {
                _maxGridHeight = maxGridHeight ?? gridHeight
                cardsCollectionChanged(_maxGridHeight)
            }
            return
        }
        
        self.cards.removeAll()
        
        for card in cards {
            let cardWithImage = CardWithImage(card: card, loadingImageSource: getLoadingImagePath(card))
            
            self.cards.append(cardWithImage)
        }
        _previousCards = cards
        
        cardsCollectionChanged(maxGridHeight)
    }
    
    private func cardsCollectionChanged(_ maxGridHeight: Int? = nil) {
        let cardCount = cards.count
        if cardCount == 0 {
            return
        }
        
        let columns = cardCount == 4 ? 2 : min(cardCount, GridCardImages.MaxColumns)
        let rows = Int(ceil(Double(cardCount) / Double(columns)))
        
        let cardRatio = CardAspectRatio
        var cardWidth = GridCardImages.GridWidth / columns
        var cardHeight = GridCardImages.GridHeight / rows

        if Double(cardWidth) / Double(cardHeight) > cardRatio {
            cardWidth = Int(Double(cardHeight) * cardRatio)
        } else {
            cardHeight = Int(Double(cardWidth) / cardRatio)
        }

        if let maxGridHeight, cardHeight * rows > maxGridHeight {
            let scaleFactor = Double(maxGridHeight) / Double(cardHeight * rows)
            cardWidth = Int(Double(cardWidth) * scaleFactor)
            cardHeight = Int(Double(cardHeight) * scaleFactor)
        }

        self.cardWidth = min(cardWidth, Int(GridCardImages.MaxCardWidth))
        self.cardHeight = min(cardHeight, Int(GridCardImages.MaxCardHeight))
        
        gridWidth = columns * self.cardWidth
        gridHeight = rows * self.cardHeight + 35
        
        DispatchQueue.main.async {
            guard let collectionView = self.collectionView else {
                return
            }
            if let flow = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout {
                flow.itemSize = NSSize(width: self.cardWidth, height: self.cardHeight)
            }
            
            collectionView.reloadData()
        }
    }
    
    func setTitle(_ title: String) {
        self.title = title
    }
    
    private func calculateCardMargin() -> NSEdgeInsets {
        let scaleFactor = Double(cardHeight) / GridCardImages.BaseCardHeight
        let topBottomMargin = -13 * scaleFactor
        let leftRightMargin = -2 * scaleFactor
        return NSEdgeInsets(top: topBottomMargin, left: leftRightMargin, bottom: topBottomMargin, right: leftRightMargin)
    }
    
    // MARK: - properties
    
    static let MaxColumns = 3
    
    static let GridWidth = 600
    static let GridHeight = 750

    private static let MaxCardWidth = 256 * 0.7
    private static let MaxCardHeight = 388 * 0.7
    
    private var _maxGridHeight = GridHeight

    private let CardAspectRatio = MaxCardWidth / MaxCardHeight
    
    private static let BaseCardHeight = 194.0
    
    var cardWidth = 128
    var cardHeight = 194
    
    var gridWidth = 600
    var gridHeight = 750
    
    @objc dynamic var title = ""
    @IBOutlet var titleLabel: NSTextField!
    
    // MARK: - Collection View
    let cardImageItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "cardImageItemIdentifier")
 
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0 else {
            return 0
        }
        return cards.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: cardImageItemIdentifier, for: indexPath) as? GridCardImageItem, indexPath.item < cards.count else {
            return NSCollectionViewItem()
        }
        let card = cards[indexPath.item]
        let insets = calculateCardMargin()
        item.leftConstraint.constant = insets.left
        item.rightConstraint.constant = insets.right
        item.topConstraint.constant = insets.top
        item.bottomConstraint.constant = insets.bottom
        item.imageView?.image = NSImage(named: card.loadingImageSource)
        if card.card.baconCard {
            ImageUtils.cardArtBG(for: card.card.id, baconTriple: false, completion: { img in
                DispatchQueue.main.async {
                    item.imageView?.image = img
                }
            })
        } else {
            ImageUtils.cardArt(for: card.card.id, completion: { img in
                DispatchQueue.main.async {
                    item.imageView?.image = img
                }
            })
        }
        return item
    }
}
