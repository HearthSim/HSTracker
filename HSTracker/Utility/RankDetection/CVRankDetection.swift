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
        //
        
        let directory = NSTemporaryDirectory()
        let fileName = NSUUID().UUIDString
        let fullURL = NSURL.fileURLWithPathComponents([directory, fileName])
        
        if let tempfile = fullURL?.path,
            data = screenshot.TIFFRepresentation {
            
            data.writeToFile(tempfile, atomically: true)
            let rank = detector.detectRank(tempfile)
            Log.info?.message("detected rank for \(player) : \(rank)")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fullURL!)
            } catch {
                Log.info?.message("Failed to remove temp")
            }
            return Int(rank)
        }
        return nil
    }
}