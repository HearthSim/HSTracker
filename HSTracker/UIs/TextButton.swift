//
//  TextColor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class TextButton: NSButton {
    @IBInspectable open var textColor: NSColor = NSColor.black
    @IBInspectable open var textSize: CGFloat = 10
    @IBInspectable var horizontalPadding: CGFloat = 0
    @IBInspectable var verticalPadding: CGFloat = 0

    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.width += self.horizontalPadding
        size.height += self.verticalPadding
        return size
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = alignment

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColor, .font: NSFont.systemFont(ofSize: textSize), .paragraphStyle: titleParagraphStyle]
        self.attributedTitle = NSMutableAttributedString(string: self.title, attributes: attributes)
    }
}
