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
            // Passing image by file because converting NSImage to cv::Mat was
            // causing random bugs and segfaults
            //
            
            let directory = NSTemporaryDirectory()
            let fileName = NSUUID().UUIDString
            let fullURL = NSURL.fileURLWithPathComponents([directory, fileName])
            
            let tempfile = fullURL!.path

            let data = screenshot.TIFFRepresentation!
            data.writeToFile(tempfile!, atomically: true)
            
            let rank = detector.detectRank(tempfile)
            Log.info?.message("detected rank : \(rank)")
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