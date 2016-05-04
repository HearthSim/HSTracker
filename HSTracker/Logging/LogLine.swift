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

class LogLineZone {
    var namespace: LogLineNamespace
    var logLevel = 1
    var filePrinting = "true"
    var consolePrinting = "false"
    var screenPrinting = "false"

    init(namespace: LogLineNamespace) {
        self.namespace = namespace
    }

    func isValid() -> Bool {
        return logLevel == 1 && filePrinting == "true"
            && consolePrinting == "false" && screenPrinting == "false"
    }

    func toString() -> String {
        return "[\(namespace)]\n" +
            "LogLevel=1\n" +
            "FilePrinting=true\n" +
            "ConsolePrinting=false\n" +
            "ScreenPrinting=false\n"
    }
}
