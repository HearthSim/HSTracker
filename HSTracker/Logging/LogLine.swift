/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

enum LogLineNamespace : String {
    case Power, Net, Asset, Bob, Rachelle, Arena, LoadingScreen
}

class LogLine {
    var time: Int
    var namespace: LogLineNamespace
    var line: String

    init(namespace: LogLineNamespace, time: Int, line: String) {
        self.namespace = namespace
        self.time = time
        self.line = line
    }
}

let _LogLineNamespaceAllValues: [LogLineNamespace] = [.Power, .Net, .Asset, .Bob, .Rachelle, .Arena, .LoadingScreen]