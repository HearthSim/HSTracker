//
//  MercenariesTaskListView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/3/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit
import HearthMirror
import SwiftUI

// For views that can be loaded from nib file
protocol NibLoadable {
    // Name of the nib file
    static var nibName: String { get }
    static func createFromNib(owner: NSView, in bundle: Bundle) -> Self
}

extension NibLoadable where Self: NSView {

    // Default nib name must be same as class name
    static var nibName: String {
        return String(describing: Self.self)
    }

    static func createFromNib(owner: NSView, in bundle: Bundle = Bundle.main) -> Self {
        var topLevelArray: NSArray?
        guard bundle.loadNibNamed(NSNib.Name(nibName), owner: owner, topLevelObjects: &topLevelArray) else {
            fatalError("Failed to load NIB \(nibName)")
        }
        if let topLevelArray = topLevelArray {
            let views = [Any](topLevelArray).filter { $0 is Self }
            if let result = views.last as? Self {
                return result
            }
            fatalError("Failed to find view in topLevelArray")
        }
        fatalError("Unexpected nil found for topLevelArray")
    }
}

struct MercenariesTaskViewModel {
    var title: String
    var description: String
    var progressText: String
    var progress: Double
    var card: Card?
    
    init(mercCard: Card, title: String, description: String, quota: Int, progress: Int) {
        self.card = mercCard
        self.title = title
        self.description = description
        let completed = progress >= quota
        progressText = completed ? NSLocalizedString("Completed!", comment: "") : "\(progress) / \(quota)"
        self.progress = 1.0 * Double(progress) / Double(quota)
    }
}

class MercenariesTask: NSView, NibLoadable {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
    }
}

@IBDesignable
class MercenariesTaskView: NSView {
    var task: MercenariesTaskViewModel?
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var progressTextLabel: NSTextField!
    @IBOutlet weak var ellipseView: NSView!
    
    @IBOutlet weak var progressBar: NSBox!
    @IBOutlet weak var actualBar: NSBox!
    @IBOutlet weak var mercenaryImageView: NSImageView!
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        let view = MercenariesTask.createFromNib(owner: self)
        addSubview(view)
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false

        if let gray = ellipseView {
            let path = NSBezierPath(ovalIn: gray.bounds)
            let maskLayer = CAShapeLayer()
            maskLayer.frame = gray.bounds
            maskLayer.path = path.cgPath
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            maskLayer.fillColor = NSColor.fromHexString(hex: "#221717")!.cgColor
            gray.layer = maskLayer
        }
        if let art = mercenaryImageView {
            art.wantsLayer = true
            let clipPath = NSBezierPath(ovalIn: NSRect(x: 20, y: 8, width: 70, height: 94))
            let clipLayer = CAShapeLayer()
            clipLayer.frame = art.bounds
            clipLayer.path = clipPath.cgPath
            art.layer?.mask = clipLayer
        }
    }
    
    func update() {
        guard let task = task else { return }
        
        titleLabel.stringValue = task.title
        if let astr = task.description.htmlToAttributedString {
            descriptionLabel.attributedStringValue = astr
        } else {
            descriptionLabel.stringValue = task.description
        }
        progressTextLabel.stringValue = task.progressText

        actualBar.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: task.progress).isActive = true

        if let artImg = ImageUtils.cachedArt(cardId: task.card?.id ?? "") {
            mercenaryImageView.image = artImg
        } else {
            ImageUtils.art(for: task.card?.id ?? "", completion: { x in
                if let img = x {
                    DispatchQueue.main.async {
                        self.mercenaryImageView.image = img
                    }
                }
            })
        }
    }
    
    func setTask(task: MercenariesTaskViewModel) {
        self.task = task
        update()
    }
}

class MercenariesTaskList: NSView {

    var tasks = [MercenariesTaskViewModel]()
    var _taskData: [MirrorMercenariesTaskData]?
    var gameNoticeVisible: Bool = false
    
    init() {
        super.init(frame: NSRect.zero)

//        orientation = .vertical
//        spacing = 4.0
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createGameNotice() -> NSBox {
        let gameNotice = NSBox()
        gameNotice.boxType = .custom
        gameNotice.titlePosition = .noTitle
        gameNotice.cornerRadius = 3
        gameNotice.borderWidth = 2
        gameNotice.contentViewMargins = NSSize()
        gameNotice.borderColor = NSColor.fromHexString(hex: "#110C0C")!
        gameNotice.fillColor = NSColor.fromHexString(hex: "#221717")!
        gameNotice.translatesAutoresizingMaskIntoConstraints = false
        
        let notice = NSLocalizedString("Task progress will update after the game", comment: "")
        let noticeText = NSTextField(labelWithString: notice)
        noticeText.cell = VerticallyAlignedTextFieldCell()
        noticeText.cell?.title = notice
        noticeText.alignment = .center
        noticeText.font = NSFont(name: "Arial", size: 14)
        noticeText.textColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
        gameNotice.contentView = noticeText
        noticeText.centerXAnchor.constraint(equalTo: gameNotice.centerXAnchor).isActive = true
        noticeText.topAnchor.constraint(equalTo: gameNotice.topAnchor, constant: 8).isActive = true
        noticeText.bottomAnchor.constraint(equalTo: gameNotice.bottomAnchor, constant: -8).isActive = true
        noticeText.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        noticeText.translatesAutoresizingMaskIntoConstraints = false

        return gameNotice
    }
    
    fileprivate func updateContent() {
        let rect = SizeHelper.mercenariesTaskListView()
        frame = NSRect(x: 0, y: 0, width: rect.width, height: rect.height)

        for view in subviews {
            view.removeFromSuperview()
        }
        var previous: MercenariesTaskView?
        
        for task in tasks {
            let view = MercenariesTaskView(frame: NSRect.zero)
            view.setTask(task: task)
            view.setContentHuggingPriority(NSLayoutConstraint.Priority(251), for: .horizontal)
            view.identifier = NSUserInterfaceItemIdentifier(task.title)
            addSubview(view)
            view.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
            view.heightAnchor.constraint(equalToConstant: 104).isActive = true
            if let previous = previous {
                view.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 4).isActive = true
                view.widthAnchor.constraint(equalTo: previous.widthAnchor, constant: 0).isActive = true
            }
            previous = view
        }
        
        if gameNoticeVisible {
            let gameNotice = createGameNotice()
            addSubview(gameNotice)
            gameNotice.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
            if let previous = previous {
                gameNotice.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 4).isActive = true
                gameNotice.leftAnchor.constraint(equalTo: previous.leftAnchor, constant: 55).isActive = true
            }
            bottomAnchor.constraint(equalTo: gameNotice.bottomAnchor).isActive = true
        } else if let previous = previous {
            bottomAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
        }
    }

    func update() {
        if _taskData == nil || _taskData?.count == 0 {
            _taskData = MirrorHelper.getMercenariesTaskData()
        }
        
        guard let taskData = _taskData else {
            return
        }
        
        guard let tasks = MirrorHelper.getMercenariesVisitorTasks() else {
            return
        }
        
        self.tasks = tasks.compactMap({ task -> MercenariesTaskViewModel? in
            guard let td = taskData.first(where: { $0.id == task.taskId }) else {
                return nil
            }
            let cardId = td.mercenaryDefaultDbfId.intValue != 0 ? td.mercenaryDefaultDbfId.intValue : task.visitorCardDbf.intValue
            
            guard let card = Cards.by(dbfId: cardId, collectible: false) else {
                return nil
            }
            var titleStr = td.title.replacingOccurrences(of: "$owner_merc", with: task.visitorName)
            let title = titleStr.contains(":") ? titleStr : String(format: NSLocalizedString("Task %d: %@", comment: ""), task.taskChainProgress.intValue + 1, titleStr)
            let bountyName = task.bountyHeroic ? String(format: NSLocalizedString("%@ (Heroic)", comment: ""), task.bountyName) : task.bountyName
            var descStr = td.taskDescription.replacingOccurrences(of: "$bounty_nd", with: bountyName).replacingOccurrences(of: "$bounty_set", with: task.bountySet).replacingOccurrences(of: "$additional_mercs", with: task.additionalMercenaries.joined(separator: ", "))
            let result = MercenariesTaskViewModel(mercCard: card, title: title, description: descStr, quota: td.quota.intValue, progress: task.progress.intValue)
            return result
        })
    }
    
    func setGameNoticeVisible(flag: Bool) {
        DispatchQueue.main.async {
            self.gameNoticeVisible = flag
            self.updateContent()
        }
    }
    
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        let backgroundColor: NSColor = NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 0.3)
//        //let backgroundColor = NSColor.clear
//        backgroundColor.set()
//        dirtyRect.fill()
//    }
}

class MercenariesTaskListView: OverWindowController {
    
    override var alwaysLocked: Bool { true }
    
    var view = MercenariesTaskList()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.contentView = view
        //self.window!.backgroundColor = NSColor.brown
    }
    
    func setGameNoticeVisible(flag: Bool) {
        view.setGameNoticeVisible(flag: flag)
    }
    
    func update() {
        view.update()
    }
    
    func updateContent() {
        view.updateContent()
    }
}
