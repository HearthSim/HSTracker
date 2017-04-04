//
//  ImageDownloader.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 21/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

final class ImageDownloader {
    var semaphore: DispatchSemaphore?

    var images: [String] = []

    let removeImages = [
        "5.0.0.12574": ["NEW1_008", "EX1_571", "EX1_166", "CS2_203", "EX1_005",
                        "CS2_084", "CS2_233", "NEW1_019", "EX1_029", "EX1_089",
                        "EX1_620", "NEW1_014"]
    ]
    func deleteImages() {
        let dir = Paths.cards

        for (patch, images) in removeImages {
            let key = "remove_images_\(patch)"
            if let _ = UserDefaults.standard.object(forKey: key) {
                continue
            }

            images.forEach {
                do {
                    let path = dir.appendingPathComponent("\($0).png")
                    try FileManager.default.removeItem(at: path)
                    Log.verbose?.message("Patch \(patch), deleting \($0) image")
                } catch {}
            }
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    func downloadImagesIfNeeded(splashscreen: Splashscreen, images: [String]) {
        self.images = images

        // check for images already present
        let destination = Paths.cards
        for image in self.images {
            let path = destination.appendingPathComponent("\(image).png")
            if FileManager.default.fileExists(atPath: path.path) {
                if NSImage(contentsOf: path) != nil {
                    self.images.remove(image)
                }
            }
        }

        if self.images.isEmpty {
            // we already have all images
            return
        }

        if let lang = Settings.hearthstoneLanguage {
            semaphore = DispatchSemaphore(value: 0)
            let total = Double(images.count)
            DispatchQueue.main.async {
                splashscreen.display(NSLocalizedString("Downloading images", comment: ""),
                                     total: total)
            }

            let langs = ["dede", "enus", "eses", "frfr", "ptbr", "ruru", "zhcn"]
            var locale = lang.lowercased()
            if !langs.contains(locale) {
                switch lang {
                case "esmx": locale = "eses"
                case "ptpt": locale = "ptbr"
                default: locale = "enus"
                }
            }

            downloadImages(language: locale, splashscreen: splashscreen)
        }
        if let semaphore = semaphore {
            let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }

    fileprivate func downloadImages(language: String, splashscreen: Splashscreen) {
        if images.isEmpty {
            if let semaphore = semaphore {
                semaphore.signal()
            }
            return
        }

        if let image = images.popLast() {
            DispatchQueue.main.async {
                splashscreen.increment(String(format:
                    NSLocalizedString("Downloading %@.png", comment: ""), image))
            }

            let path = Paths.cards.appendingPathComponent("\(image).png")
            let url = URL(string: "http://vps208291.ovh.net/cards/\(language)/\(image).png")!
            Log.verbose?.message("downloading \(url) to \(path)")

            URLSession.shared
                .downloadTask(with: URLRequest(url: url),
                              completionHandler: { (url, _, error) -> Void in
                                if error != nil {
                                    Log.error?.message("download error \(String(describing: error))")
                                    self.downloadImages(language: language,
                                                        splashscreen: splashscreen)
                                    return
                                }

                                if let url = url {
                                    if let data = try? Data(contentsOf: url) {
                                        try? data.write(to: path,
                                                        options: [.atomic])
                                    }
                                }
                                self.downloadImages(language: language,
                                                    splashscreen: splashscreen)
                }).resume()
        }
    }
}
