/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

enum LogLineNamespace: String {
    case Power, Net, Asset, Bob, Rachelle, Arena, LoadingScreen

    static func allValues() -> [LogLineNamespace] {
        return [.Power, .Net, .Asset, .Bob, .Rachelle, .Arena, .LoadingScreen]
    }
}

struct LogLine {
    let namespace: LogLineNamespace
    let time: Int
    let line: String
}
