//
//  ConstructedMulliganGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganGuidePreLobby: OverWindowController {
    @IBOutlet var stack1: NSStackView!
    @IBOutlet var stack2: NSStackView!
    @IBOutlet var stack3: NSStackView!
    @IBOutlet var outerView: NSView!
    @IBOutlet var scaleView: NSView!
    
    let viewModel = ConstructedMulliganGuidePreLobbyViewModel()
    
    var isVisible = false
    private var deferred = false
    
    override init(window: NSWindow?) {
        super.init(window: window)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    func commonInit() {
        viewModel.propertyChanged = { name in
            DispatchQueue.main.async {
                self.update(name)
            }
        }
    }

    override func awakeFromNib() {
    }
    
    func updateScaling() {
        guard window != nil else {
            logger.debug("Missing window")
            return
        }
        let rect = SizeHelper.constructedMulliganGuidePreLobbyFrame()
        // rect is already sized to the visible content (SizeHelper no longer
        // returns a 2x-oversized frame with a separate internal
        // repositioning step - see the comment there for why the old scheme
        // silently got clamped on screens without much extra vertical room),
        // so scaleView just fills the window directly, scaled up from the
        // unscaled reference bounds (matching the 238x3 / 224x3 reference
        // size the badge cells/rows are laid out at).
        scaleView.frame = NSRect(x: 0, y: 0, width: rect.width, height: rect.height)
        scaleView.bounds = NSRect(x: 0, y: 0, width: 238.0*3.0, height: 224.0*3.0)
        scaleView.needsDisplay = true
    }
    
    func update(_ property: String?) {
        let all = property == nil
        
        logger.debug("\(#function) - property \(property ?? "nil")")
        if property == "pageStatusRows" || all {
            if let stack1, let stack2, let stack3 {
                for old in stack1.arrangedSubviews {
                    old.removeFromSuperview()
                }
                for old in stack2.arrangedSubviews {
                    old.removeFromSuperview()
                }
                for old in stack3.arrangedSubviews {
                    old.removeFromSuperview()
                }

                let rows = viewModel.pageStatusRows
                var rowIndex = 0
                for row in rows {
                    for status in row {
                        let view = ConstructedMulliganSingleDeckStatus(frame: NSRect(x: 0, y: 0, width: 238, height: 96), status: status)
                        // Deliberately NOT setting view.isHidden here (see git
                        // history for the reverted attempt) - Stack1/2/3 use
                        // distribution="equalSpacing" over a *fixed* 714pt
                        // width (exactly 3*238, so it tiles with zero slack
                        // when all 3 cells are visible). Hiding an arranged
                        // subview excludes it from that distribution, and with
                        // fewer visible cells equalSpacing redistributes the
                        // full 714pt across whatever remains - e.g. a single
                        // remaining visible cell gets centered across the
                        // whole row instead of staying in its own column.
                        // Confirmed live: a cell meant for column 0 rendered
                        // at column 1's position once its siblings were
                        // hidden. Each cell keeps its own reserved 238pt slot
                        // (matching its box.isHidden-driven inner content
                        // hiding in ConstructedMulliganSingleDeckStatus) so
                        // column alignment with Hearthstone's own deck boxes
                        // stays correct; a real "shrink when blank" needs a
                        // distribution that doesn't redistribute on hide
                        // (e.g. per-cell explicit constraints instead of
                        // equalSpacing), not arrangedSubview.isHidden.
                        switch rowIndex {
                        case 0:
                            stack1.addArrangedSubview(view)
                        case 1:
                            stack2.addArrangedSubview(view)
                        case 2:
                            stack3.addArrangedSubview(view)
                        default:
                            continue
                        }
                    }
                    rowIndex += 1
                }
            } else {
                deferred = true
            }
        }
        if property == "visibility" || all {
            isVisible = viewModel.visibility
            AppDelegate.instance().coreManager.game.updateConstructedMulliganOverlays()
        }
    }
}
