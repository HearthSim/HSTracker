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

    func display(str: String, indeterminate: Bool) {
        information.stringValue = str
        progressBar.indeterminate = indeterminate
    }

    func display(str: String, total: Double) {
        progressBar.indeterminate = false
        information.stringValue = str
        progressBar.maxValue = total
        progressBar.doubleValue = 0
    }

    func increment(str: String? = nil) {
        progressBar.incrementBy(1)
        if let str = str {
            information.stringValue = str
        }
    }
}
