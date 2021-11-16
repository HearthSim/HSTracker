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

class MercenariesTask: NSView {
    var task: MercenariesTaskViewModel
    
    init(frame: NSRect, task: MercenariesTaskViewModel) {
        self.task = task
        super.init(frame: frame)
        
        let box = NSBox(frame: NSRect(x: 50, y: 0, width: frame.width - 50, height: frame.height))
        box.fillColor = NSColor.fromHexString(hex: "#221717")!
        box.borderColor = NSColor.fromHexString(hex: "#110C0C")!
        box.borderWidth = 2
        box.cornerRadius = 3
        box.titlePosition = .noTitle
        box.contentViewMargins = NSSize()
        box.boxType = NSBox.BoxType.custom
        
        let dock = NSView()
        dock.frame = NSRect(x: 50, y: 8, width: box.frame.width - 58, height: frame.height - 16)
        box.addSubview(dock)

        let pframe = NSRect(x: 0, y: 0, width: dock.frame.width, height: 26)
        
        let progress = NSBox(frame: pframe)
        progress.fillColor = NSColor.fromHexString(hex: "#110C0C")!
        progress.cornerRadius = 3
        progress.titlePosition = .noTitle
        progress.borderType = .noBorder
        progress.contentViewMargins = NSSize()
        progress.boxType = NSBox.BoxType.custom
        dock.addSubview(progress)
        
        let apframe = NSRect(x: 0, y: 0, width: progress.frame.width * task.progress, height: progress.frame.height)
        let aprogress = NSBox(frame: apframe)
        aprogress.fillColor = NSColor.fromHexString(hex: "#6E1E1E")!
        aprogress.cornerRadius = 3
        aprogress.titlePosition = .noTitle
        aprogress.contentViewMargins = NSSize()
        aprogress.boxType = NSBox.BoxType.custom
        aprogress.borderType = .noBorder
        progress.addSubview(aprogress)
        
        let ptext = NSTextField(labelWithString: task.progressText)
        ptext.cell = VerticallyAlignedTextFieldCell()
        ptext.cell?.title = task.progressText
        ptext.font = NSFont(name: "Arial", size: 12)
        ptext.frame = NSRect(x: 0, y: 0, width: progress.frame.width, height: progress.frame.height)
        ptext.alignment = .center
        ptext.textColor = .white
        progress.addSubview(ptext)

        let desc = NSTextField(labelWithString: task.description)
        desc.cell = VerticallyAlignedTextFieldCell()
        desc.cell?.title = task.description
        desc.font = NSFont(name: "Arial", size: 12)
        desc.textColor = .white
        desc.frame = NSRect(x: 0, y: progress.frame.maxY + 4, width: dock.frame.width, height: 26)
        dock.addSubview(desc)

        let titleLabel = NSTextField(labelWithString: task.title)
        titleLabel.cell = VerticallyAlignedTextFieldCell()
        titleLabel.cell?.title = task.title
        titleLabel.font = NSFont(name: "Arial", size: 16)
        titleLabel.textColor = .white
        titleLabel.frame = NSRect(x: 0, y: desc.frame.maxY + 4, width: dock.frame.width, height: 28)
        dock.addSubview(titleLabel)

        addSubview(box)
        
        let gray = NSView(frame: NSRect(x: 10, y: 0, width: 80, height: 104))
        let path = NSBezierPath(ovalIn: gray.bounds)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = gray.bounds
        maskLayer.path = path.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.fillColor = box.fillColor.cgColor
        gray.layer = maskLayer
        
        addSubview(gray)

        let grid = NSView(frame: NSRect(x: 0, y: 1, width: 100, height: 100))
        addSubview(grid)
        
        let art = NSImageView(frame: NSRect(x: -5, y: -5, width: 110, height: 110))
        art.wantsLayer = true
        let clipPath = NSBezierPath(ovalIn: NSRect(x: 20, y: 8, width: 70, height: 94))
        let clipLayer = CAShapeLayer()
        clipLayer.frame = art.bounds
        clipLayer.path = clipPath.cgPath
        art.layer?.mask = clipLayer
        if let artImg = ImageUtils.cachedArt(cardId: task.card?.id ?? "") {
            art.image = artImg
        } else {
            ImageUtils.art(for: task.card?.id ?? "", completion: { x in
                if let img = x {
                    DispatchQueue.main.async {
                        art.image = img
                    }
                }
            })
        }
        grid.addSubview(art)

        let mercFrame = NSImageView(image: NSImage(imageLiteralResourceName: "merc_frame"))
        mercFrame.imageScaling = .scaleProportionallyUpOrDown
        mercFrame.frame = NSRect(x: 0, y: 1, width: 100, height: 100)

        grid.addSubview(mercFrame)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MercenariesTaskList: NSStackView {

    var tasks = [MercenariesTaskViewModel]()
    var _taskData: [MirrorMercenariesTaskData]?
    var gameNotice: NSBox = NSBox()
    var gameNoticeVisible: Bool = false
    
    init() {
        super.init(frame: NSRect.zero)

        orientation = .vertical
        spacing = 4.0
        translatesAutoresizingMaskIntoConstraints = false
        
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
//        noticeText.bottomAnchor.constraint(equalTo: gameNotice.bottomAnchor, constant: 8).isActive = true
        noticeText.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        noticeText.translatesAutoresizingMaskIntoConstraints = false
        
        gameNotice.bottomAnchor.constraint(equalTo: noticeText.bottomAnchor, constant: 8).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateContent() {
        let rect = SizeHelper.mercenariesTaskListView()
        frame = NSRect(x: 0, y: 0, width: rect.width, height: rect.height)

        for view in subviews {
            view.removeFromSuperview()
        }
        var previous: MercenariesTask?
        
        for task in tasks {
            let frame = NSRect(x: 0, y: 0, width: rect.width, height: 104)
            let view = MercenariesTask(frame: frame, task: task)
            view.identifier = NSUserInterfaceItemIdentifier(task.title)
            addView(view, in: NSStackView.Gravity.bottom)
            view.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
            view.heightAnchor.constraint(equalToConstant: 104).isActive = true
            if let previous = previous {
                view.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 4).isActive = true
            }
            previous = view
        }
        if gameNoticeVisible {
            addView(gameNotice, in: NSStackView.Gravity.bottom)
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
        if _taskData == nil {
            _taskData = MirrorHelper.getMercenariesTaskData()
        }
        
        guard let taskData = _taskData else {
            return
        }
        
        guard let tasks = MirrorHelper.getMercenariesVisitorTasks() else {
            return
        }
        
        self.tasks = tasks.compactMap({ task in
            guard let td = taskData.first(where: { $0.id == task.taskId }) else {
                return nil
            }
            guard let card = Cards.by(dbfId: td.mercenaryDefaultDbfId.intValue, collectible: false) else {
                return nil
            }
            let title = td.title.contains(":") ? td.title : String(format: NSLocalizedString("Task %d: %@", comment: ""), task.taskChainProgress.intValue + 1, td.title)
            let result = MercenariesTaskViewModel(mercCard: card, title: title, description: td.taskDescription, quota: td.quota.intValue, progress: task.progress.intValue)
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
