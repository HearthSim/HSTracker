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

class InitialConfiguration: NSWindowController, NSComboBoxDataSource,
NSComboBoxDelegate, NSOpenSavePanelDelegate {

    @IBOutlet weak var hstrackerLanguage: NSComboBox!
    @IBOutlet weak var hearthstoneLanguage: NSComboBox!
    @IBOutlet var saveButton: NSButton!
    @IBOutlet var hearthstonePath: NSTextField!
    @IBOutlet weak var choosePath: NSButton!
    @IBOutlet weak var checkImage: NSImageView!

    var completionHandler: (() -> Void)?

    override func windowDidLoad() {
        super.windowDidLoad()

        hearthstoneLanguage.reloadData()
        hstrackerLanguage.reloadData()

        if let path = Hearthstone.findHearthstone() {
            hearthstonePath.stringValue = path
            hearthstonePath.isEnabled = false
            choosePath.isEnabled = false
        } else {
            checkImage.image = NSImage(named: "error")

            let alert = NSAlert()
            alert.alertStyle = .critical
            // swiftlint:disable line_length
            alert.messageText = NSLocalizedString("Can't find Hearthstone, please select Hearthstone.app", comment: "")
            // swiftlint:enable line_length
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.beginSheetModal(for: self.window!, completionHandler: nil)
        }
    }

    // MARK: - Button actions
    @IBAction func exit(_ sender: AnyObject) {
        NSApplication.shared().terminate(nil)
    }

    @IBAction func save(_ sender: AnyObject) {
        if hearthstoneLanguage.indexOfSelectedItem < 0
            || hstrackerLanguage.indexOfSelectedItem < 0
            || hearthstonePath.stringValue == "" {
            saveButton.isEnabled = false
            return
        }
        let hstracker = Language.hstrackerLanguages[hstrackerLanguage.indexOfSelectedItem]
        let hearthstone = Language.hsLanguages[hearthstoneLanguage.indexOfSelectedItem]

        Settings.instance.hearthstoneLanguage = hearthstone
        Settings.instance.hsTrackerLanguage = hstracker
        Settings.instance.hearthstoneLogPath = hearthstonePath.stringValue

        if let completionHandler = self.completionHandler {
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        self.window!.close()
    }

    @IBAction func choosePath(_ sender: AnyObject) {
        let openDialog = NSOpenPanel()
        openDialog.delegate = self
        openDialog.canChooseDirectories = false
        openDialog.allowsMultipleSelection = false
        openDialog.allowedFileTypes = ["app"]
        openDialog.nameFieldStringValue = "Hearthstone.app"
        openDialog.title = NSLocalizedString("Please select your Hearthstone app", comment: "")
        if openDialog.runModal() == NSModalResponseOK {
            if let url = openDialog.urls.first {
                let path = url.path
                hearthstonePath.stringValue = path.replace("/Hearthstone.app", with: "")
                checkImage.image = NSImage(named: "check")
            }
        }
        checkToEnableSave()
    }

    // MARK: - NSComboBoxDataSource methods
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        if aComboBox == hstrackerLanguage {
            return Language.hstrackerLanguages.count
        } else if aComboBox == hearthstoneLanguage {
            return Language.hearthstoneLanguages.count
        }

        return 0
    }

    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        var language: String?
        if aComboBox == hstrackerLanguage {
            language = Language.hstrackerLanguages[index]
        } else if aComboBox == hearthstoneLanguage {
            language = Language.hearthstoneLanguages[index]
        }

        if let language = language {
            let locale = Locale(identifier: language)
            return (locale as NSLocale).displayName(forKey: NSLocale.Key.identifier,
                                                    value: language)!.capitalized
        } else {
            return ""
        }
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        checkToEnableSave()
    }

    func checkToEnableSave() {
        saveButton.isEnabled = (hearthstoneLanguage.indexOfSelectedItem != -1
            && hstrackerLanguage.indexOfSelectedItem != -1
            && hearthstonePath.stringValue != "")
    }

    // MARK: - NSOpenSavePanelDelegate
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        if url.path.hasSuffix(".app") {
            return url.lastPathComponent == "Hearthstone.app"
        } else {
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path,
                isDirectory: &isDir) && isDir.boolValue
        }
    }
}
