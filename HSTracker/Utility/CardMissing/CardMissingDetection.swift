//
//  CardMissingDetection.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class CardMissingDetection {
    var detector: CardMissingDetectorWrapper

    init () {
        detector = CardMissingDetectorWrapper()
        if !detector.didInit() {
            Log.warning?.message("Failed to initialize lock detector. Retrying once...")
            detector = CardMissingDetectorWrapper()
            if !detector.didInit() {
                Log.error?.message("Still failed to initialize lock detector. "
                    + "Lock detection will be unavailiable.")
            }
        }
    }

    func silverLock() -> Bool {
        if let screenshot = ImageUtilities.screenshotFirstCard() {
            return findLock(screenshot: screenshot)
        }
        return false
    }

    func goldenLock() -> Bool {
        if let screenshot = ImageUtilities.screenshotFirstCard() {
            return findLock(screenshot: screenshot)
        }
        return false
    }

    private func findLock(screenshot: NSImage) -> Bool {
        // Passing image by file because converting NSImage to cv::Mat was
        // causing random bugs and segfaults

        if !detector.didInit() {
            return false
        }

        let directory = NSTemporaryDirectory()
        let fileName = UUID().uuidString
        let fullURL = URL(fileURLWithPath: directory).appendingPathComponent(fileName)

        let tempfile = fullURL.path
        if let data = screenshot.tiffRepresentation {

            try? data.write(to: URL(fileURLWithPath: tempfile), options: [.atomic])
            let lock = detector.detectLock(tempfile)

            do {
                try FileManager.default.removeItem(at: fullURL)
            } catch {
                Log.info?.message("Failed to remove temp")
            }

            Log.verbose?.message("Found lock \(lock)")

            if lock >= 0 {
                Log.info?.message("detected lock \(lock)")
                return true
            }
        }
        return false
    }
}
