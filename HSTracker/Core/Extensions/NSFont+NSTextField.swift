//
//  NSFont+NSTextField.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSFont {
  /**
   Will return the best font conforming to the descriptor which will fit in the provided bounds.
   */
  static func bestFittingFontSize(for text: String, in bounds: CGRect, fontDescriptor: NSFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> CGFloat {
    let constrainingDimension = min(bounds.width, bounds.height)
    let properBounds = CGRect(origin: .zero, size: bounds.size)
    var attributes = additionalAttributes ?? [:]

    let infiniteBounds = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
    var bestFontSize: CGFloat = constrainingDimension

      for fontSize in stride(from: bestFontSize, through: 0, by: -0.5) {
      let newFont = NSFont(descriptor: fontDescriptor, size: fontSize)
      attributes[.font] = newFont

      let currentFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)

      if properBounds.contains(currentFrame) {
        bestFontSize = fontSize
        break
      }
    }
    return bestFontSize
  }

  static func bestFittingFont(for text: String, in bounds: CGRect, fontDescriptor: NSFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> NSFont {
    let bestSize = bestFittingFontSize(for: text, in: bounds, fontDescriptor: fontDescriptor, additionalAttributes: additionalAttributes)
    // TODO: Safely unwrap this later
    return NSFont(descriptor: fontDescriptor, size: bestSize)!
  }
}

extension NSTextField {
  /// Will auto resize the contained text to a font size which fits the frames bounds.
  /// Uses the pre-set font to dynamically determine the proper sizing
  func fitTextToBounds() {
    guard let currentFont = font else {
      return
    }
    let text = stringValue
    let bestFittingFont = NSFont.bestFittingFont(for: text, in: alignmentRect(forFrame: bounds), fontDescriptor: currentFont.fontDescriptor, additionalAttributes: basicStringAttributes)
    font = bestFittingFont
  }

  private var basicStringAttributes: [NSAttributedString.Key: Any] {
    var attribs = [NSAttributedString.Key: Any]()

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = self.alignment
    paragraphStyle.lineBreakMode = self.lineBreakMode
    attribs[.paragraphStyle] = paragraphStyle

    return attribs
  }
}
