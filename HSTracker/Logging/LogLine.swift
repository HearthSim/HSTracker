/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import CleanroomLogger

enum LogLineNamespace: String {
    case Achievements, AdTracking, All, Arena, Asset, BIReport, BattleNet, Becca, Ben, Bob, Brian,
    BugReporter, Cameron, CardbackMgr, ChangedCards, ClientRequestManager, ConfigFile, Crafting,
    DbfXml, DeckHelper, DeckRuleset, DeckTray, Derek, DeviceEmulation, Downloader, EndOfGame,
    EventTiming, FaceDownCard, FullScreenFX, GameMgr, Graphics, Hand, HealthyGaming, Henry,
    InnKeepersSpecial, JMac, Jay, Josh, Kyle, LoadingScreen, Mike, MikeH, MissingAssets, Net,
    Packet, Party, PlayErrors, Power, RAF, Rachelle, Reset, Robin, Ryan, Sound, Spectator, Store,
    UpdateManager, UserAttention, Yim, Zone

    static func usedValues() -> [LogLineNamespace] {
        return [.Power, .Net, .Asset, .Bob, .Rachelle, .Arena, .LoadingScreen]
    }
    
    static func allValues() -> [LogLineNamespace] {
        return [.Achievements, .AdTracking, .All, .Arena, .Asset, .BIReport, .BattleNet, .Becca,
         .Ben, .Bob, .Brian, .BugReporter, .Cameron, .CardbackMgr, .ChangedCards, 
         .ClientRequestManager, .ConfigFile, .Crafting, .DbfXml, .DeckHelper, .DeckRuleset, 
         .DeckTray, .Derek, .DeviceEmulation, .Downloader, .EndOfGame, .EventTiming, 
         .FaceDownCard, .FullScreenFX, .GameMgr, .Graphics, .Hand, .HealthyGaming, .Henry, 
         .InnKeepersSpecial, .JMac, .Jay, .Josh, .Kyle, .LoadingScreen, .Mike, .MikeH, 
         .MissingAssets, .Net, .Packet, .Party, .PlayErrors, .Power, .RAF, .Rachelle, .Reset, 
         .Robin, .Ryan, .Sound, .Spectator, .Store, .UpdateManager, .UserAttention, .Yim, .Zone]
    }
}

struct LogLine: CustomStringConvertible {
    let namespace: LogLineNamespace
    let time: Double
    let line: String

    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()

    init(namespace: LogLineNamespace, line: String) {
        self.namespace = namespace
        self.line = line
        self.time = self.dynamicType.parseTime(line)
    }

    static func parseTime(line: String) -> Double {
        guard line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 20 else {
            return NSDate.now.timeIntervalSince1970
        }

        let fromLine = line.substringWithRange(2, location: 16)

        let dateTime = NSDate(fromString: fromLine,
                              inFormat: "HH:mm:ss.SSSS",
                              timeZone: nil)
        let today = NSDate()
        let dateComponents = NSDateComponents()
        dateComponents.year = today.year
        dateComponents.month = today.month
        dateComponents.day = today.day
        dateComponents.hour = dateTime.hour
        dateComponents.minute = dateTime.minute
        dateComponents.second = dateTime.second
        dateComponents.nanosecond = dateTime.nanosecond
        dateComponents.timeZone = NSTimeZone(name: "UTC")

        if let date = NSCalendar.currentCalendar().dateFromComponents(dateComponents) {
            if date > NSDate.now {
                date.addDays(-1)
            }
            return date.timeIntervalSince1970
        }
        return NSDate.now.timeIntervalSince1970
    }

    var description: String {
        return "\(namespace): \(NSDate(timeIntervalSince1970: time)): \(line)"
    }
}

class LogLineZone: CustomStringConvertible {
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
            //"Verbose=true\n"
    }

    var description: String {
        return "[\(namespace): " +
            "LogLevel=\(logLevel), " +
            "FilePrinting=\(filePrinting), " +
            "ConsolePrinting=\(consolePrinting), " +
            "ScreenPrinting=\(screenPrinting)]"
    }
}
