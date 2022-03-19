//
//  FillImageView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/05/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

open class FillImageView: NSImageView {

  open override var image: NSImage? {
    get {
        return super.image
    }
    set {
      self.layer = CALayer()
      self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
      self.layer?.contents = newValue
      self.wantsLayer = true

      super.image = newValue
    }
  }
}
