//
//  NSView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSView {
    func borders(for edges: [NSRectEdge], width: CGFloat = 1, color: NSColor = .black) {
        let allSpecificBorders: [NSRectEdge] = [.maxY, .minY, .minX, .maxX]

        for edge in allSpecificBorders {
            let ident = NSUserInterfaceItemIdentifier(rawValue: "\(edge)")

            if let v = subviews.first(where: { x in x.identifier == ident}) {
                v.removeFromSuperview()
            }
            
            if edges.contains(edge) {
                let v = NSView()
                v.identifier = ident
                v.wantsLayer = true
                v.layer?.backgroundColor = color.cgColor
                v.translatesAutoresizingMaskIntoConstraints = false
                addSubview(v)
                
                var horizontalVisualFormat = "H:"
                var verticalVisualFormat = "V:"
                
                switch edge {
                case NSRectEdge.minY:
                    horizontalVisualFormat += "|-(0)-[v]-(0)-|"
                    verticalVisualFormat += "[v(\(width))]-(0)-|"
                case NSRectEdge.maxY:
                    horizontalVisualFormat += "|-(0)-[v]-(0)-|"
                    verticalVisualFormat += "|-(0)-[v(\(width))]"
                case NSRectEdge.minX:
                    horizontalVisualFormat += "|-(0)-[v(\(width))]"
                    verticalVisualFormat += "|-(0)-[v]-(0)-|"
                case NSRectEdge.maxX:
                    horizontalVisualFormat += "[v(\(width))]-(0)-|"
                    verticalVisualFormat += "|-(0)-[v]-(0)-|"
                default:
                    break
                }
                
                self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: horizontalVisualFormat, options: .directionLeadingToTrailing, metrics: nil, views: ["v": v]))
                self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: verticalVisualFormat, options: .directionLeadingToTrailing, metrics: nil, views: ["v": v]))
            }
        }
    }
}
