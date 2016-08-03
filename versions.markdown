#### 0.17.4
- Save replays (Support for http://www.zerotoheroes.com/)
- Sync with Track-o-Bot

#### 0.17.3
- Update portuguese translation
- Correct errors introduced by patch 5.2.0.13619
- Correct an issue where opponent in-hand card was not resetted 
- Add support for Morgl the Oracle
- Refactor a lot of code related to cards

#### 0.17.2
- Correct a crash when opening statistics window
- Update portuguese translation
- Add a loader when importing a deck from the net

#### 0.17.1
- Add an option to add notes on game end
- Add a ladder climb prediction based on deck statistic
- Should correct a crash with rank detection

#### 0.17
- Fix positions for trackers, board damage, opponent card huds, ...
- Add an option to show your deck name in tracker
- Add statistics window
- Correct a bug with Bear Trap on the secret helper if your opponent have 7 minions
- Correct the attack/health for C'Thun when a card is played
- Add a check for corrupted card images in Deck Manager
- Rank detection is now done by image recognition
- Correct a bug where cost reduction from Thaurissan was not correct if your opponent have more than 1 Thaurissan on board
- HSTracker can now detect your arena deck. After you finished to draft your arena deck, go to menu Decks -> Save -> Save arena deck
- HSTracker now correctly synchronize your arena decks and matches with Hearthstats
- Add an option to clear statistics

#### 0.16.11
- Option to hide board damage
- Chinese translation update
- Add Gitter link in the deck manager

#### 0.16.10
- Added themes and set Dark as default
- Better font for russian players
- Better rank detection (at least, I hope)
- Show class and deck name when editing a deck
- Add shortcuts to add cards on deck edition (⌘+F to search, ⌘+1 -> 9 to select card)
- Add an option to show your opponent class and name in his tracker
- Option to save your current deck or your opponent's one
- Ability to archive and unarchive decks
- Show win loss ratio for in tracker
- Add an option to close HSTracker when Hearthstone is closed
- Undo/Redo in deck creation/edition
- Ability to sort decks in manager
- Add an option to change in-hand color
- Add an icon for Wild decks in manager
- Show detailled information on deck manager
- On-board damage information
- Fatigue counter

#### 0.16.9
- Fixed a bug where HSTracker would crash when adding a deck
- Decks are back again in the menu
- Add a deathrattle counter for N'Zoth

#### 0.16.8
- UTC is now used, which improve parsing logs
- Improve Hearthstats UI
- It's now possible to disconnect from Hearthstats
- Fix some crashes
- Refactoring of log reading
- Refactoring of some code to be more Swift-compliant
- Secret helper should appear again
- Update deck statistics on game end
- Better end game handling

#### 0.16.7
- Startup crash finally corrected
- Add an option to see opponent created cards

#### 0.16.6
- This should avoid crash on startup

#### 0.16.5
- Better error handling

#### 0.16.4
- Some Swift refactoring + add some test to help avoiding some crashes
- Floating card should correctly disappear
- Some UI improvements
- Images download should be faster
- Better Hearthstone log.config check and modification
- Decks windows should be visible for streamers
- A backup of decks.json is now done when HSTracker starts
- Correct a crash when importing a deck from Hearthpwn deckbuilder
- Correct an issue where HSTracker could crash when parsing some log lines
- Use a text framework to (try to) avoid some crashes

#### 0.16.3
- Correct issues reported with HockeyApp
- Code cleanup
- C’Thun and Spell (Yogg-Saron) counter frames

#### 0.16.2
- WoTOG corrections
- Helper to select Hearthstone folder
- Add options to show/hide player and opponent draw and card cout
- Correct an error where frames were not hide when Hearthstone lost focus
- Secret based on format

#### 0.16.1
- Update to The Whispers of the Old Gods
- Correct an issue where net decks would not be imported
- Remove /Logs from Hearthstone path in the settings

#### 0.16
HSTracker has been fully rewritten (from A to Z)
- New UI for trackers
- New log parser
- New everything in fact :D

#### 0.13.4
- Update Sparkle to prevent vulnerabilities
- Update some english words

#### 0.13.3
- Add "show number 1 on trackers" option (issue #235)
- Add another gem color for free cards (issue #230)
- Better thread usage (issues #196, #237 and #224)
- Better opponent name detection (issue #236)
- Correct Golden Monkey, Death Lord, Excavated Evil (issues #262 and #267)


#### 0.13.2
- Add option to change log path (issue #217)
- Add option to disable card number overlay (issue #223)
- Add option to disable card rarity colors
- Sort decks per class in the deck menu

#### 0.13.1
- Correct a crash when entity is unknown
- Correctly check for file offset is log file does not exists
- New icon, give me some swag :D

#### 0.13
- Add a auto move and resize window mode (issue #31)
- It is now possible to click on the tracker, they will not take focus (issue #134)
- Add a card tracker for the opponent (issue #30)
- Add japonese cards database
- Add portuguese and chinese locales
- Add chinese cards
- Use the new logger (issue #189)
- Updated to League of Explorers
- Add frame rarity for cards

#### 0.12.8
- Correct a crash when a date is not a date (oO)
- HSTracker like your decks and want to create them multiple times on HeartStats

#### 0.12.7
- Bugfixes

#### 0.12.6
- (A lot of) Bugfixes (thanks HockeyApp, and you guys which send reports)
- Change loader to add some text and progress
- Change HSTracker logs, should stop crash on 10.8
- Joust cards are now shown on the deck of your opponent
- Rewrite the popup on the deck manager to use a cleaner one

#### 0.12.5
- Heroes are back

#### 0.12.4
- Bugfixes

Hey guys, sorry for 0.12 start which is not glorious, patch 0.3 + a lot of downtime on HearthStats reveal a lot of bugs.
I'm trying to do my best to correct them as fast as possible !

#### 0.12.3
- Correct some crashes
- Add Sparkle for auto-update stuff !

#### 0.12.2
- Correct the invalid update message
- Correct a crash if HearthStats is down and the timeout is too long
- Add HockeyApp to help getting error message. Please always accept to send the crash logs !

#### 0.12.1
- Bugfixes !

#### 0.12
- Fix : should run correctly on 10.8
- Fix : upload on HearthStats
- Add an option to rebuild card database (menu HSTracker -> rebuild card database)
- Fix : brawl is now correctly detected
- Support TGT

#### 0.11.4
- Correct the save button on "non-full" decks
- The timer is now correctly hidden on HSTracker start when show_timer is not checked
- Add an option to hide the opponent tracker
- Correct a crash when importing hearthstats decks
- Correct an error with the deck selection from menu
- Correct scroll on 10.8 and 10.9

#### 0.11.3
- Correct a bug when importing old hearthstats decks
- Correct a bug with save opponent deck button
- The timer can now be hidden correctly
- Correct a crash when there are Hearthstats issue
- Change version system to allow version x.y (ie 1.1)

#### 0.11.2
- Correct a bug where HSTracker will crash when canceling a modal dialog in the deck manager
- Support for new heroes

#### 0.11.1
- Correct a bug where the last deck was deleted on right-click instead of the selected one
- Add a verification for the config.log file
- Improve deck manager opening
- Add turn timer (beta). There is a know bug with the first turn which starts too soon.

#### 0.11
##### HearthStats support
- HSTracker is now the official HearthStats uploader of OsX !
- Import, save your decks and matches in HearthStats through HSTracker

##### New / Bugfixes
- Card font should be better on retina display
- Better rank / mode handling for stats / HearthStats
- Added some notifications through Notification Center
- Fade cards in the deck manager when you can not add it anymore in your deck
- Added an option to save/restore the last played deck. This allow the log reader to restart your game correctly when HSTracker crashed or you forgot to start it
- Added a HearthStats skin
- Mana curve is now visible when you click on a deck
- Added some actions on right-click on deck list

#### 0.10.3
- You can now import multiple files at the same time
- Choose **Decks** -> **Save all** to export all your decks
- Add an option to reset all data. **WARNING** this operation is irreversible, save your decks before !!! (Statistics will be lost)
- Deck manager : ⌘-f to search, ⌘-s to save your deck, ⌘-w to close the deck and ⇧⌘-w to close the manager

#### 0.10.2
- Fix duplicate deck on menu
- Fix opponent tracker reset

#### 0.10.1
- Correct a crash in 0.10
- Add Twitter link
- *New*: Display mana curve on the deck manager
- *New*: Import decks from txt files. The deck must have the following format : **2 Mirror Image** or **2xMirror Image** or **2 CS2_027**. You can also have the card name if your hearthstone locale. Caution, make sure to have only one card per line.
- *New*: Add an option to do not display in-hand cards. As soon as you draw a card, HSTracker consider it is not anymore in your deck and fade or remove the card from tracker, if no more in deck.
- *New*: Add a button at the end of a game to save your opponent s deck. Of course, it will only save the cards your opponent played.
- *New* __beta__: Deck now can have multiple versions. Also, win/loss statistics are now saved and displayed in the deck manager.
- Correction of the arena tag from netdeck

#### 0.9
- Better font for asian languages
- *New*: Option for card count and draw chance
- Gnomish inventor transformed card is now "discarded"
- *New*: Display card on trackers hover

#### 0.8
- Complete rewrite of the log analysis using the code base from [Hearthstone-Deck-Tracker](https://github.com/Epix37/Hearthstone-Deck-Tracker)
- HSTracker now listen for Hearthstone to be active and set its "modality" according.

#### 0.7
- Card count, draw chance are now only available on trackers, also change color is available
- Gang Up is supported, added a green frame for this kind of cards
- Cards reset when "remove" option is selected

#### 0.6
- *New* : **Full support for Blackrock Mountain**
- *New* : flash the cards on draw (color editable in prefs)
- *New* : better font for asian and cyrillic languages
- *New* : name of the windows can now be fixed
- *New* : import from [HearthArena](http://www.heartharena.com)
- Better error handling in import decks
- *New* : cardcount for current deck in the Deck Manager
- *New* : shortcut to lock/unlock windows (⌘l)
- *New* : open a deck from the menu, as well as reset trackers (⌘r)
- *New* : option to show card count on a single line
- *New* : option to reset trackers on game end
- *New* : option to change HSTracker language
- Handle correctly steal, discard, tracking
- *New* : deck manager can now be close with ⌘w
- *New* : add an option to change trackers size (small, medium or big)
- *New* : add an option to toggle card count style

#### 0.5
- Correction of the message when you save a deck
- Better end game detection
- *New* : windows can be locked in the settings
- *New* : transparency of the windows can be set in the settings
- *New* : player and opponent card count windows
- *New* : card draw chance on deck hover
- *New* : deck manager images available in de, en, es, fr, pt and ru

#### 0.4
- *New* : support for OS X 10.8
- Better start and end game detection
- *New* : support for arena decks !
- *New* : add an option to remove cards instead of fade them (when you play the last)
- *New* : export decks to text files
- Better language detection
- *New* : import from [Hearthstats](https://hearthstats.net/)
- *New* : import from [Hearthhead](http://www.hearthhead.com/) (all languages available)
- *New* : import from [Hearthnews](https://hearthnews.fr/)
- Cards import optimizations
- Remove scrollbars

#### 0.3
- *New* : deck manager ! Enjoy creating and editing deck directly from the app
- Correct a bug where the app keep asking about update
- Some corrections & optimisations
- German translation
- *New* : NetDeck import

#### 0.2
- Loading screen
- Force the language detection
- HSTracker on 10.9
- Bugfixes

#### 0.1 - Initial release (2015-03-13)
- Import decks from http://www.hearthpwn.com/decks (english)
- Import decks from http://www.hearthpwn.com/deckbuilder (english)
- Import decks from http://www.hearthstone-decks.com (french)
- Display your deck and the cards you played
- Display the cards your opponent played
- Support for all Hearthstone languages
- HSTracker available in french and english
