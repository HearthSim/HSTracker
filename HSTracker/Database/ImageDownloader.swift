//
//  ImageDownloader.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 21/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Alamofire
import CleanroomLogger

final class ImageDownloader {
    var semaphore: dispatch_semaphore_t?

    let removeImages = [
        "5.0.0.12574": ["NEW1_008", "EX1_571", "EX1_166", "CS2_203", "EX1_005",
            "CS2_084", "CS2_233", "NEW1_019", "EX1_029", "EX1_089", "EX1_620", "NEW1_014"]
    ]
    func deleteImages() {
        if let destination = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory,
                                                                 .UserDomainMask, true).first {
            for (patch, images) in removeImages {
                let key = "remove_images_\(patch)"
                if let _ = NSUserDefaults.standardUserDefaults().objectForKey(key) {
                    continue
                }

                images.forEach {
                    do {
                        let path = "\(destination)/HSTracker/cards/\($0).png"
                        try NSFileManager.defaultManager().removeItemAtPath(path)
                        Log.verbose?.message("Patch \(patch), deleting \($0) image")
                    } catch {}
                }
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
            }
        }
    }

    func downloadImagesIfNeeded(allImages: [String], splashscreen: Splashscreen) {
        if let destination = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory,
                                                                 .UserDomainMask, true).first {
            do {
                let path = "\(destination)/HSTracker/cards"
                try NSFileManager.defaultManager()
                    .createDirectoryAtPath(path,
                                           withIntermediateDirectories: true,
                                           attributes: nil)
            } catch { }

            var images = allImages
            // check for images already present
            for image in images {
                let path = "\(destination)/HSTracker/cards/\(image).png"
                if NSFileManager.defaultManager().fileExistsAtPath(path) {
                    images.remove(image)
                }
            }

            if images.isEmpty {
                // we already have all images
                return
            }

            if let lang = Settings.instance.hearthstoneLanguage {
                semaphore = dispatch_semaphore_create(0)
                let total = Double(images.count)
                dispatch_async(dispatch_get_main_queue()) {
                    splashscreen.display(NSLocalizedString("Downloading images", comment: ""),
                                         total: total)
                }

                let langs = ["dede", "enus", "eses", "frfr", "ptbr", "ruru", "zhcn"]
                var locale = lang.lowercaseString
                if !langs.contains(locale) {
                    switch lang {
                    case "esmx": locale = "eses"
                    case "ptpt": locale = "ptbr"
                    default: locale = "enus"
                    }
                }

                downloadImages(&images, language: locale,
                               destination: destination,
                               splashscreen: splashscreen)
            }
            if let semaphore = semaphore {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
        }
    }

    private func downloadImages(inout images: [String], language: String,
                                      destination: String, splashscreen: Splashscreen) {
        if images.isEmpty {
            if let semaphore = semaphore {
                dispatch_semaphore_signal(semaphore)
            }
            return
        }

        if let image = images.popLast() {
            dispatch_async(dispatch_get_main_queue()) {
                splashscreen.increment(String(format:
                    NSLocalizedString("Downloading %@.png", comment: ""), image))
            }

            let path = "\(destination)/HSTracker/cards/\(image).png"
            // swiftlint:disable line_length
            let url = NSURL(string: "http://vps208291.ovh.net/cards/\(language)/\(image).png")!
            Log.verbose?.message("downloading \(url) to \(path)")

            let task = NSURLSession.sharedSession().downloadTaskWithRequest(NSURLRequest(URL: url),
                                                                            completionHandler: {
                                                                                (url, response, error) -> Void in
                if error != nil {
                    Log.error?.message("download error \(error)")
                    self.downloadImages(&images, language: language,
                        destination: destination,
                        splashscreen: splashscreen)
                    return
                }

                if let url = url {
                    if let data = NSData(contentsOfURL: url) {
                        data.writeToFile(path, atomically: true)
                    }
                }
                self.downloadImages(&images, language: language,
                    destination: destination, splashscreen: splashscreen)
            })
            // swiftlint:enable line_length
            task.resume()
        }
    }
}
