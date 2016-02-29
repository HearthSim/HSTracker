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

class InitialConfiguration: NSWindowController, NSComboBoxDataSource, NSComboBoxDelegate {

    @IBOutlet var hstrackerLanguage: NSComboBox?
    @IBOutlet var hearthstoneLanguage: NSComboBox?
    @IBOutlet var saveButton: NSButton!
    @IBOutlet var hearthstonePath: NSTextField!

    var completionHandler: (() -> Void)?

    let hsLanguages = ["deDE", "enUS", "esES", "esMX", "frFR", "itIT", "koKR", "plPL", "ptBR", "ruRU", "zhCN", "zhTW", "jaJP"]
    let hearthstoneLanguages = ["de_DE", "en_US", "es_ES", "es_MX", "fr_FR", "it_IT", "ko_KR", "pl_PL", "pt_BR", "ru_RU", "zh_CN", "zh_TW", "ja_JP"]
    let hstrackerLanguages = ["de", "en", "fr", "it", "pt-br", "zh-cn", "es"]

    override func windowDidLoad() {
        super.windowDidLoad()

        if let hearthstoneLanguage = self.hearthstoneLanguage {
            hearthstoneLanguage.reloadData()
        }
        if let hstrackerLanguage = self.hstrackerLanguage {
            hstrackerLanguage.reloadData()
        }
    }

    // MARK: - Button actions
    @IBAction func exit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(nil)
    }

    @IBAction func save(sender: AnyObject) {
        let hstracker = hstrackerLanguages[hstrackerLanguage!.indexOfSelectedItem]
        let hearthstone = hsLanguages[hearthstoneLanguage!.indexOfSelectedItem]

        Settings.instance.hearthstoneLanguage = hearthstone
        Settings.instance.hsTrackerLanguage = hstracker
        Settings.instance.hearthstoneLogPath = hearthstonePath!.stringValue

        if let completionHandler = self.completionHandler {
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler()
            }
        }
        self.window!.close()
    }

    @IBAction func choosePath(sender: AnyObject) {
        let openDialog = NSOpenPanel()
        openDialog.canChooseDirectories = true
        openDialog.allowsMultipleSelection = false
        openDialog.title = NSLocalizedString("Please choose your Hearthstone directory", comment: "")
        if openDialog.runModal() == NSModalResponseOK {
            if let url = openDialog.URLs.first {
                hearthstonePath.stringValue = url.path! + "/Logs"
            }
        }
        checkToEnableSave()
    }

    // MARK: - NSComboBoxDataSource methods
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        if aComboBox == hstrackerLanguage {
            return hstrackerLanguages.count
        } else if aComboBox == hearthstoneLanguage {
            return hearthstoneLanguages.count
        }

        return 0
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        var language: String?
        if aComboBox == hstrackerLanguage {
            language = hstrackerLanguages[index]
        } else if aComboBox == hearthstoneLanguage {
            language = hearthstoneLanguages[index]
        }

        if let language = language {
            let locale = NSLocale(localeIdentifier: language)
            return locale.displayNameForKey(NSLocaleIdentifier, value: language)!.capitalizedString
        } else {
            return ""
        }
    }

    func comboBoxSelectionDidChange(notification: NSNotification) {
        checkToEnableSave()
    }

    func checkToEnableSave() {
        if let saveButton = self.saveButton {
            saveButton.enabled = (hearthstoneLanguage!.indexOfSelectedItem != -1 && hstrackerLanguage!.indexOfSelectedItem != -1 && hearthstonePath!.stringValue != "")
        }
    }
}
