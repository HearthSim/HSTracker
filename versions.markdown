# 1.0.1
## Fixes:
- Fixed a crash when the deck manager UI tries to save/update a deck
- Fixed a crash when saving current player / opponent deck
- Fixed an error where arena score were not shown if value contains non-numeric character
- Fixed an error where game mode were not updated when switching from a game mode to another
- Fixed an issue where tracker GUI's were hidden even when app was active
- Clear trackers on game end now works properly
- Fixed an issue when uploading to HSReplay

## New
- Add an indicator for bad card when multiple (arena helper)

# 1.0
## Fixes:
- Fixed quests not increasing spell counter.
- Improved German translations.
- Improved Chinese translations.
- Added an option to use macOS's Notification Center
- Fixed memory issues and decreased general memory usage.
- Fixed an issue where opponent name and class were not updated.
- Fixed an issue where golden cards were not exported to Hearthstone.

## New: 
- Auto check and download arena helper card tier list.
- Hero power has been added to damage counter.
- Add a button to open your Track-o-bot profile in the settings.

## Changes:
- Rewrite of a lot of core parts.

# 0.20.1
## Fixes:
- Fixed an issue where Quests would trigger the secret list.
- Fixed an issue where some cards were not in the correct sets.
- Fixed an issue where the Tracking (Hunter) pick would not be tracked correctly.

# 0.20
## New:
- Update to Journey to Un'Goro

# 0.19.3
## Fixes:
- Fixed an issue where HSTracker was using a lot of memory and cpu (eventually ?)
- Fixed an issue where HSTracker was sending bad log lines to HsReplay
- Fixed an issue where some UI parts were not visible on fullscreen mode 

# 0.19.2
## New:
- HSTracker is now localized in korean
- There's an arena helper available when you craft your arena deck
- Add an option to hide all trackers when not in game
- Updated for patch 7.1.0.17720

## Fixes:
- Fixed an issue where HSTracker was using a lot of memory and cpu
- Fixed an issue where HSTracker was not saving all informations in statistics
- Fixed an issue where HSTracker was not uploading correctly to HsReplay
- Decks imported from Hearthstone are now visible in deck menu and dock menu

# 0.19.1
## Fixes:
- Fixed an issue where the opponent tracker should remain empty until the end of the game
- Fixed an issue that caused an invalid mirror state caused by the game crashing at startup
- Fixed an issue where HSTracker was using a lot of memory
- Fixed a crash when exporting to hearthstone

# 0.19
## Breaking change

HearthStats has not been updated for Mean Streets of Gadgetzan and will likely remain unmaintained.
Syncing causes your local decks to lose their MSG cards. HearthStats support is now disabled for all users.

We are very sorry about the inconvenience and are working on a much improved replacement system!

## Breaking change 2

Starting from this version, HSTracker is signed with my Apple developper account. You have to download manually this version from [hsdecktracker.net](https://hsdecktracker.net/hstracker/download/) since the update system will not allow this signature change.

## Breaking change 3

HSTracker now use a new system to improve your tracking. It allows HSTracker to auto-import decks from Hearthstone, detect ranks, game modes, ...
You will be asked to authorize HSTracker to read the memory of Hearthstone. There's no other modification done to your system.
_Please note_ that this version will delete your statistics, this is due to a big modification of the statistic system.

## Changes:
- Improve the "new deck" window
- Improve the tracker "refresh"
- Add a option to fully reset your HSReplay account
- Better support for MSG cards

## New:
- Add a jade counter
- New way to get your data, which allows to get 
- Decks imported from Hearthstone for all game modes (arena, brawl, constructed)
- Format (wild/standard)
- Correct rank
- Arena draft choice (which allows something like arena helper) (NOT in this version, planned for future release)
- Arena reward tracking (NOT in this version, planned for future release)
- Collection manager (we know the cards you have)
- Pack opening, end season rewards, ... (NOT in this version, planned for future release)
- Add an option to prefer golden cards when exporting a deck to Hearthstone

## Fixes:
- The "Use deck" in the deck manager is working again
- The new way we get data should correct a lot of issues
- Statistics are now correctly saved again
- Better support of HsReplay
- Improve log reading speed

# 0.18.5
## Fixes:
- HSTracker now correctly save the opponent deck on game end

## New:
- Add a visual effect when you add a card in the deck manager
- Add a right-click menu on the deck manager
- Support for *Mean Streets of Gadgetzan*
- Add the chance to top deck a card (when you hover a card in your tracker)

## Changes:
- Due to some problem with card images, the deck manager and the hovering on the tracker now show a tooltip of the card. I'm still trying to fix the issue, but in the meantime...
- Tiles (little cards image) are now downloaded. It can take sometime the first time you show a card for the image to be downloaded.

# 0.18.4
## Fixes: 
- Arena deck will now appear correctly as arena deck on HsReplay
- Add an option to auto archive arena decks on run end
- You should no more be asked to save your arena deck once it's saved
- Statistics are now correctly shown for arena decks
- Add an icon in the deck manager when a deck is marked as arena
- Add an icon in the deck manager on arena deck when the run is finished
- Arena deck imported by HSTracker are now correctly marked as "arena deck"
- Correct an issue where HSTracker was not visible with fullscreen Hearthstone
- Hearthstats decks are fetched correctly now 
- Correct the build number from Hearthstone
- Multiple crashes fixes

## Changes:
- Hearthstats and Track-o-Bot login/logout is now done from settings (use *⌘,* to open them)

# 0.18.3
## Fixes:
- Correct a crash when saving an arena deck

# 0.18.2
## New:
- HSTracker now show his status on the dock icon

## Fixes:
- Effigy is now removed correctly from secret helper
- Export to Hearthstone should pick the correct card now (ie: C'Thun) and the second card if the first is not available
- Hearthhead import works with their new website

## Internal
- HSTracker have been converted to swift 3
- Complete refactor of all UI system for trackers.
- Decks and statistics are now saved in a realm database. This should improve their stability.

# 0.18.1  
## Fixes:  
- Correct a crash happening on opening Update panel on Preferences
- Prince Malchezaar is no more shown too early

## New:
- Import decks from https://tempostorm.com, http://www.hearthstoneheroes.de and http://www.hearthstonetopdeck.com
- Add a tiny size for trackers

## Changes: 
- Get the Hearthstone build number from Hearthstone file to improve HSReplay 

## Internal
- HSTracker have been converted to swift 2.3
- HSTracker now only use PowerTaskList log to track your game

# 0.18
- HSTracker now synchronize your games with HSReplay.net ! Enjoy your replays now !
- You can play with Hearthstone on fullscreen !
- HSTracker use its own notifications, they should not appear under decklist anymore
- Trackers should not disappear again when they « auto-position trackers » is checked
- Add a release channel for betas
- Support for importing decks from http://www.hearthstonetopdecks.com
- Add a graveyard and minion count in the trackers
- Add an option to export your deck to Hearthstone (This is a BETA feature !)
- You can now change your deck with a right click on the dock icon !
- Add a huge size for trackers
- Minor bugfixes

# 0.17.4.2
- Correctly send the rank to Track-o-Bot

# 0.17.4.1
- Correct a crash when opening preferences

# 0.17.4
- Save replays (Support for http://www.zerotoheroes.com/)
- Sync with Track-o-Bot
- Add season in statistics
- Update to patch 6.0.0.13921
- UI improvments (crash correction)

# 0.17.3
- Update portuguese translation
- Correct errors introduced by patch 5.2.0.13619
- Correct an issue where opponent in-hand card was not resetted 
- Add support for Morgl the Oracle
- Refactor a lot of code related to cards

# 0.17.2
- Correct a crash when opening statistics window
- Update portuguese translation
- Add a loader when importing a deck from the net

# 0.17.1
- Add an option to add notes on game end
- Add a ladder climb prediction based on deck statistic
- Should correct a crash with rank detection

# 0.17
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

# 0.16.11
- Option to hide board damage
- Chinese translation update
- Add Gitter link in the deck manager

# 0.16.10
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

# 0.16.9
- Fixed a bug where HSTracker would crash when adding a deck
- Decks are back again in the menu
- Add a deathrattle counter for N'Zoth

# 0.16.8
- UTC is now used, which improve parsing logs
- Improve Hearthstats UI
- It's now possible to disconnect from Hearthstats
- Fix some crashes
- Refactoring of log reading
- Refactoring of some code to be more Swift-compliant
- Secret helper should appear again
- Update deck statistics on game end
- Better end game handling

# 0.16.7
- Startup crash finally corrected
- Add an option to see opponent created cards

# 0.16.6
- This should avoid crash on startup

# 0.16.5
- Better error handling

# 0.16.4
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

# 0.16.3
- Correct issues reported with HockeyApp
- Code cleanup
- C’Thun and Spell (Yogg-Saron) counter frames

# 0.16.2
- WoTOG corrections
- Helper to select Hearthstone folder
- Add options to show/hide player and opponent draw and card cout
- Correct an error where frames were not hide when Hearthstone lost focus
- Secret based on format

# 0.16.1
- Update to The Whispers of the Old Gods
- Correct an issue where net decks would not be imported
- Remove /Logs from Hearthstone path in the settings

# 0.16
HSTracker has been fully rewritten (from A to Z)
- New UI for trackers
- New log parser
- New everything in fact :D

# 0.13.4
- Update Sparkle to prevent vulnerabilities
- Update some english words

# 0.13.3
- Add "show number 1 on trackers" option (issue #235)
- Add another gem color for free cards (issue #230)
- Better thread usage (issues #196, #237 and #224)
- Better opponent name detection (issue #236)
- Correct Golden Monkey, Death Lord, Excavated Evil (issues #262 and #267)


# 0.13.2
- Add option to change log path (issue #217)
- Add option to disable card number overlay (issue #223)
- Add option to disable card rarity colors
- Sort decks per class in the deck menu

# 0.13.1
- Correct a crash when entity is unknown
- Correctly check for file offset is log file does not exists
- New icon, give me some swag :D

# 0.13
- Add a auto move and resize window mode (issue #31)
- It is now possible to click on the tracker, they will not take focus (issue #134)
- Add a card tracker for the opponent (issue #30)
- Add japonese cards database
- Add portuguese and chinese locales
- Add chinese cards
- Use the new logger (issue #189)
- Updated to League of Explorers
- Add frame rarity for cards

# 0.12.8
- Correct a crash when a date is not a date (oO)
- HSTracker like your decks and want to create them multiple times on HeartStats

# 0.12.7
- Bugfixes

# 0.12.6
- (A lot of) Bugfixes (thanks HockeyApp, and you guys which send reports)
- Change loader to add some text and progress
- Change HSTracker logs, should stop crash on 10.8
- Joust cards are now shown on the deck of your opponent
- Rewrite the popup on the deck manager to use a cleaner one

# 0.12.5
- Heroes are back

# 0.12.4
- Bugfixes

Hey guys, sorry for 0.12 start which is not glorious, patch 0.3 + a lot of downtime on HearthStats reveal a lot of bugs.
I'm trying to do my best to correct them as fast as possible !

# 0.12.3
- Correct some crashes
- Add Sparkle for auto-update stuff !

# 0.12.2
- Correct the invalid update message
- Correct a crash if HearthStats is down and the timeout is too long
- Add HockeyApp to help getting error message. Please always accept to send the crash logs !

# 0.12.1
- Bugfixes !

# 0.12
- Fix : should run correctly on 10.8
- Fix : upload on HearthStats
- Add an option to rebuild card database (menu HSTracker -> rebuild card database)
- Fix : brawl is now correctly detected
- Support TGT

# 0.11.4
- Correct the save button on "non-full" decks
- The timer is now correctly hidden on HSTracker start when show_timer is not checked
- Add an option to hide the opponent tracker
- Correct a crash when importing hearthstats decks
- Correct an error with the deck selection from menu
- Correct scroll on 10.8 and 10.9

# 0.11.3
- Correct a bug when importing old hearthstats decks
- Correct a bug with save opponent deck button
- The timer can now be hidden correctly
- Correct a crash when there are Hearthstats issue
- Change version system to allow version x.y (ie 1.1)

# 0.11.2
- Correct a bug where HSTracker will crash when canceling a modal dialog in the deck manager
- Support for new heroes

# 0.11.1
- Correct a bug where the last deck was deleted on right-click instead of the selected one
- Add a verification for the config.log file
- Improve deck manager opening
- Add turn timer (beta). There is a know bug with the first turn which starts too soon.

# 0.11
## HearthStats support
- HSTracker is now the official HearthStats uploader of OsX !
- Import, save your decks and matches in HearthStats through HSTracker

## New / Bugfixes
- Card font should be better on retina display
- Better rank / mode handling for stats / HearthStats
- Added some notifications through Notification Center
- Fade cards in the deck manager when you can not add it anymore in your deck
- Added an option to save/restore the last played deck. This allow the log reader to restart your game correctly when HSTracker crashed or you forgot to start it
- Added a HearthStats skin
- Mana curve is now visible when you click on a deck
- Added some actions on right-click on deck list

# 0.10.3
- You can now import multiple files at the same time
- Choose **Decks** -> **Save all** to export all your decks
- Add an option to reset all data. **WARNING** this operation is irreversible, save your decks before !!! (Statistics will be lost)
- Deck manager : ⌘-f to search, ⌘-s to save your deck, ⌘-w to close the deck and ⇧⌘-w to close the manager

# 0.10.2
- Fix duplicate deck on menu
- Fix opponent tracker reset

# 0.10.1
- Correct a crash in 0.10
- Add Twitter link
- *New*: Display mana curve on the deck manager
- *New*: Import decks from txt files. The deck must have the following format : **2 Mirror Image** or **2xMirror Image** or **2 CS2_027**. You can also have the card name if your hearthstone locale. Caution, make sure to have only one card per line.
- *New*: Add an option to do not display in-hand cards. As soon as you draw a card, HSTracker consider it is not anymore in your deck and fade or remove the card from tracker, if no more in deck.
- *New*: Add a button at the end of a game to save your opponent s deck. Of course, it will only save the cards your opponent played.
- *New* __beta__: Deck now can have multiple versions. Also, win/loss statistics are now saved and displayed in the deck manager.
- Correction of the arena tag from netdeck

# 0.9
- Better font for asian languages
- *New*: Option for card count and draw chance
- Gnomish inventor transformed card is now "discarded"
- *New*: Display card on trackers hover

# 0.8
- Complete rewrite of the log analysis using the code base from [Hearthstone-Deck-Tracker](https://github.com/Epix37/Hearthstone-Deck-Tracker)
- HSTracker now listen for Hearthstone to be active and set its "modality" according.

# 0.7
- Card count, draw chance are now only available on trackers, also change color is available
- Gang Up is supported, added a green frame for this kind of cards
- Cards reset when "remove" option is selected

# 0.6
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

# 0.5
- Correction of the message when you save a deck
- Better end game detection
- *New* : windows can be locked in the settings
- *New* : transparency of the windows can be set in the settings
- *New* : player and opponent card count windows
- *New* : card draw chance on deck hover
- *New* : deck manager images available in de, en, es, fr, pt and ru

# 0.4
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

# 0.3
- *New* : deck manager ! Enjoy creating and editing deck directly from the app
- Correct a bug where the app keep asking about update
- Some corrections & optimisations
- German translation
- *New* : NetDeck import

# 0.2
- Loading screen
- Force the language detection
- HSTracker on 10.9
- Bugfixes

# 0.1 - Initial release (2015-03-13)
- Import decks from http://www.hearthpwn.com/decks (english)
- Import decks from http://www.hearthpwn.com/deckbuilder (english)
- Import decks from http://www.hearthstone-decks.com (french)
- Display your deck and the cards you played
- Display the cards your opponent played
- Support for all Hearthstone languages
- HSTracker available in french and english
