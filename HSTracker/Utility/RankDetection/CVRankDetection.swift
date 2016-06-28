//
//  CVRankDetection.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/18/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class CVRankDetection {
    var detector: CVRankDetectorWrapper

    init () {
        detector = CVRankDetectorWrapper()
        if !detector.didInit() {
            Log.warning?.message("Failed to initialize rank detector. Retrying once...")
            detector = CVRankDetectorWrapper()
            if !detector.didInit() {
                // swiftlint:disable line_length
                Log.error?.message("Still failed to initialize rank detector. Rank detection will be unavailiable.")
                // swiftlint:enable line_length
            }
        }
    }
    
    func playerRank() -> Int? {
        if let screenshot = ImageUtilities.screenshotPlayerRank() {
            return findRank(screenshot, player: .Player)
        }
        return nil
    }
    
    func opponentRank() -> Int? {
        if let screenshot = ImageUtilities.screenshotOpponentRank() {
            return findRank(screenshot, player: .Opponent)
        }
        return nil
    }
    
    private func findRank(screenshot: NSImage, player: PlayerType) -> Int? {
        // Passing image by file because converting NSImage to cv::Mat was
        // causing random bugs and segfaults
        
        if !detector.didInit() {
            return nil
        }
        
        let directory = NSTemporaryDirectory()
        let fileName = NSUUID().UUIDString
        let fullURL = NSURL.fileURLWithPathComponents([directory, fileName])
        
        if let tempfile = fullURL?.path,
            data = screenshot.TIFFRepresentation {
            
            data.writeToFile(tempfile, atomically: true)
            let rank = detector.detectRank(tempfile)

            do {
                try NSFileManager.defaultManager().removeItemAtURL(fullURL!)
            } catch {
                Log.info?.message("Failed to remove temp")
            }
            
            
            if rank >= 0 {
                Log.info?.message("detected rank for \(player) : \(rank)")
                return Int(rank)
            } else if rank == -2 {
                //swiftlint:disable line_length
                Log.error?.message("Called detectRank on bad CVRankDetector. This should never happen.")
                //swiftlint:enable line_length
                return nil
            } else if rank == -3 {
                //swiftlint:disable line_length
                Log.error?.message("Rank detection failed in detectRank due to std::length_error thing")
                //swiftlint:enable line_length
                return nil
            } else {
                Log.info?.message("Found no rank for \(player)")
                return nil
            }
        }
        return nil
    }
}