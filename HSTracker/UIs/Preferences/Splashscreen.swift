/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Cocoa

class Splashscreen: NSWindowController {
    @IBOutlet var information: NSTextField!
    @IBOutlet var progressBar: NSProgressIndicator!

    func display(_ str: String, indeterminate: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let information, let progressBar else {
                return
            }
            information.stringValue = str
            progressBar.isIndeterminate = indeterminate
            progressBar.startAnimation(nil)
        }
    }

    func display(_ str: String, total: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let information, let progressBar else {
                return
            }
            progressBar.isIndeterminate = false
            information.stringValue = str
            progressBar.maxValue = total
            progressBar.doubleValue = 0
        }
        
    }

    func increment(_ str: String? = nil) {
        // UI should be adjusted on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.progressBar.increment(by: 1)
            if let str = str {
                self.information.stringValue = str
            }
        }
    }
}
