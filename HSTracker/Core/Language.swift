/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

class Language {
    var languageChooser: LanguageChooser?

    func isLanguageSet() -> Bool {
        return Settings.instance.hearthstoneLanguage != nil && Settings.instance.hsTrackerLanguage != nil
    }

    func presentLanguageChooserWithCompletion(completion: () -> Void) {
        languageChooser = LanguageChooser()
        languageChooser!.completionHandler = completion
        languageChooser!.showWindow(nil)
        languageChooser!.window?.orderFrontRegardless()
    }
}
