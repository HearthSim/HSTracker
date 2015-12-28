#### 0.13.3
- Add "show number 1 on trackers" option (issue #235)
- Add another gem color for free cards (issue #230)
- Better thread usage (issue #196, #237 and #224)
- Better opponent name detection (issue #236)

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
