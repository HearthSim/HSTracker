//
//  NSImageViewScaleAspectFill.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/14/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

@IBDesignable
class NSImageViewScaleAspectFill: NSImageView {

    @IBInspectable
    var scaleAspectFill: Bool = false

    override func awakeFromNib() {
        // Scaling : .scaleNone mandatory
        if scaleAspectFill { self.imageScaling = .scaleNone }
    }

    override func draw(_ dirtyRect: NSRect) {

        if scaleAspectFill, let image = self.image {

            // Compute new Size
            let imageViewRatio   = image.size.height / image.size.width
            let nestedImageRatio = self.bounds.size.height / self.bounds.size.width
            var newWidth         = image.size.width
            var newHeight        = image.size.height

            if imageViewRatio > nestedImageRatio {

                newWidth = self.bounds.size.width
                newHeight = self.bounds.size.width * imageViewRatio
            } else {

                newWidth = self.bounds.size.height / imageViewRatio
                newHeight = self.bounds.size.height
            }

            image.size.width  = newWidth
            image.size.height = newHeight

        }

        // Draw AFTER resizing
        super.draw(dirtyRect)
    }
}
