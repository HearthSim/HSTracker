//
//  NSBezierPath.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSBezierPath {

  var cgPath: CGPath {
    let path = CGMutablePath()
    var points = [CGPoint](repeating: .zero, count: 3)
    for i in 0 ..< self.elementCount {
      let type = self.element(at: i, associatedPoints: &points)

      switch type {
      case .moveTo:
        path.move(to: points[0])

      case .lineTo:
        path.addLine(to: points[0])

      case .curveTo:
        path.addCurve(to: points[2], control1: points[0], control2: points[1])

      case .closePath:
        path.closeSubpath()

      @unknown default:
        break
      }
    }
    return path
  }
}
