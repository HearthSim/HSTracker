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
    @IBOutlet var information: NSTextField?
    @IBOutlet var progressBar: NSProgressIndicator?

    func display(str: String, total: Double) {
        information!.stringValue = str
        progressBar!.maxValue = total
        progressBar!.doubleValue = 0
    }

    func increment(str:String? = nil) {
        progressBar!.incrementBy(1)
        if let str = str {
            information!.stringValue = str
        }
    }
}
