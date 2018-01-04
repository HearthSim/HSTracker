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
        
        let hsPath = Settings.hearthstonePath + "/Hearthstone.app"
        if FileManager.default.fileExists(atPath: hsPath) {
            hearthstonePath.stringValue = hsPath
            hearthstonePath.isEnabled = false
            choosePath.isEnabled = false
        } else {
            checkImage.image = NSImage(named: NSImage.Name(rawValue: "error"))

            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = NSLocalizedString("Can't find Hearthstone, please select"
                + " the folder containing Hearthstone.app", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.beginSheetModal(for: self.window!, completionHandler: nil)
        }
    }

    // MARK: - Button actions
    @IBAction func exit(_ sender: Any) {
        NSApplication.shared.terminate(nil)
    }

    @IBAction func save(_ sender: Any) {
        if hearthstoneLanguage.indexOfSelectedItem < 0
            || hstrackerLanguage.indexOfSelectedItem < 0
            || hearthstonePath.stringValue == "" {
            saveButton.isEnabled = false
            return
        }
        let hstracker: Language.HSTracker = Array(Language.HSTracker.cases())[hstrackerLanguage.indexOfSelectedItem]
        let hearthstone: Language.Hearthstone = Array(Language.Hearthstone.cases())[hearthstoneLanguage.indexOfSelectedItem]

        Settings.hearthstoneLanguage = hearthstone
        Settings.hsTrackerLanguage = hstracker
        Settings.hearthstonePath = hearthstonePath.stringValue.replace("Hearthstone.app", with: "")

        if let completionHandler = self.completionHandler {
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        self.window!.close()
    }

    @IBAction func choosePath(_ sender: Any) {
        let openDialog = NSOpenPanel()
        openDialog.delegate = self
        openDialog.canChooseDirectories = false
        openDialog.allowsMultipleSelection = false
        openDialog.allowedFileTypes = ["app"]
        openDialog.nameFieldStringValue = "Hearthstone.app"
        openDialog.title = NSLocalizedString("Please select your Hearthstone app", comment: "")
        if openDialog.runModal() == NSApplication.ModalResponse.OK {
            if let url = openDialog.urls.first {
                let path = url.path
                hearthstonePath.stringValue = path.replace("/Hearthstone.app", with: "")
                checkImage.image = NSImage(named: NSImage.Name(rawValue: "check"))
            }
        }
        checkToEnableSave()
    }

    // MARK: - NSComboBoxDataSource methods
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        if aComboBox == hstrackerLanguage {
            return Array(Language.HSTracker.cases()).count
        } else if aComboBox == hearthstoneLanguage {
            return Array(Language.Hearthstone.cases()).count
        }

        return 0
    }

    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if aComboBox == hstrackerLanguage && Array(Language.HSTracker.cases()).count > index {
            return Array(Language.HSTracker.cases())[index].localizedString
        } else if aComboBox == hearthstoneLanguage && Array(Language.Hearthstone.cases()).count > index {
            return Array(Language.Hearthstone.cases())[index].localizedString
        }

        return ""
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        checkToEnableSave()
    }

    func checkToEnableSave() {
        saveButton.isEnabled = (hearthstoneLanguage.indexOfSelectedItem != -1
            && CoreManager.validatedHearthstonePath(hearthstonePath.stringValue)
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
