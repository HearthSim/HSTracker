# HSTracker

HSTracker is a [Hearthstone](http://www.playhearthstone.com/) deck tracker for Mac OsX 10.8+.

### Deck Tracker
![Deck Tracker](https://github.com/bmichotte/HSTracker/blob/master/hstracker.jpg)

### Deck Manager
![Deck Manager](https://github.com/bmichotte/HSTracker/blob/master/manager.png)

Is Blizzard okay with this?
[Yes](https://twitter.com/bdbrode/status/511151446038179840)

## Installation
- Download the last version from [the releases page](https://github.com/bmichotte/HSTracker/releases)
- Extract the archive
- Move _HSTracker.app_ to your _Applications_ directory
- Launch !
- Create a new deck from the Deck Manager or import it from [HearthPwn](http://www.hearthpwn.com) (deck and deckbuilder), [Hearthstone-decks](http://www.hearthstone-decks.com), [Hearthstats](https://hearthstats.net), [Hearthhead](http://www.hearthhead.com/) (all languages), [Hearthnews](http://www.hearthnews.fr/) or using [Netdeck](https://chrome.google.com/webstore/detail/netdeck/lpdbiakcpmcppnpchohihcbdnojlgeel)
- Starting of version 0.5, you can move/resize your windows and then lock them through the preferences panel. You can also change the transparency of the windows in the preferences.

## TODO
- statistics
- translate in more languages
- test ;) 

## Versions
#### 0.6
- *New* : flash the cards on draw (color editable in prefs)
- *New* : better font for asian and cyrillic languages
- *New* : name of the windows can now be fixed

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

## Contribution
Feel free to fork and pull-request, as well as filling [new issues](https://github.com/bmichotte/HSTracker/issues)

HSTracker is written in Ruby, using [Rubymotion](http://www.rubymotion.com/). You will need a valid Rubymotion license to build it.

To compile/run
```
bundle
rake pod:install
```

## Thanks

I took some inspiration/copy-paste from [Hearthstone-Deck-Tracker-Mac](https://github.com/Jeswang/Hearthstone-Deck-Tracker-Mac).

The base of the log analyser came from [hearthstone-tracker-osx](https://github.com/hellozimi/hearthstone-tracker-osx).

Lot of resources came from [Hearthstone-Deck-Tracker](https://github.com/Epix37/Hearthstone-Deck-Tracker).

Cards came from [Hearthhead](http://www.hearthhead.com/).

JSON data came from [Hearthstone JSON](http://hearthstonejson.com/).

## Donations
Donations are always appreciated 

[![PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=bmichotte%40gmail%2ecom&lc=US&item_name=HSTracker&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted)

## License

HSTracker is released under the [MIT license](LICENSE).