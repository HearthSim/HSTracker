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
    @IBOutlet weak var information: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!

    func display(_ str: String, indeterminate: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.information.stringValue = str
            self.progressBar.isIndeterminate = indeterminate
            self.progressBar.startAnimation(nil)
        }
    }

    func display(_ str: String, total: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.progressBar.isIndeterminate = false
            self.information.stringValue = str
            self.progressBar.maxValue = total
            self.progressBar.doubleValue = 0
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
