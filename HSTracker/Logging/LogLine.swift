/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

class LogLine {
    var time: Int
    var namespace: String
    var line: String

    init(namespace: String, time: Int, line: String) {
        self.namespace = namespace
        self.time = time
        self.line = line
    }
}
