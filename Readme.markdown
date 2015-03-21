# HSTracker

HSTracker is a [Hearthstone](http://www.playhearthstone.com/) deck tracker for Mac OsX 10.8+.

HSTracker is released under the [MIT license](LICENSE).

### Deck Tracker
![Deck Tracker](https://github.com/bmichotte/HSTracker/blob/master/hstracker.jpg)

### Deck Manager
![Deck Manager](https://github.com/bmichotte/HSTracker/blob/master/manager.png)

Is Blizzard okay with this?
[Yes](https://twitter.com/bdbrode/status/511151446038179840)

## Installation
- download the last version from [the releases page](https://github.com/bmichotte/HSTracker/releases)
- extract the archive
- move _HSTracker.app_ to your _Applications_ directory
- launch !
- create a new deck from the Deck Manager or import it from [HearthPwn](http://www.hearthpwn.com) (deck and deckbuilder), [Hearthstone-decks](http://www.hearthstone-decks.com), [Hearthstats](https://hearthstats.net), [Hearthhead](http://www.hearthhead.com/) (all languages), [Hearthnews](http://www.hearthnews.fr/) or using [Netdeck](https://chrome.google.com/webstore/detail/netdeck/lpdbiakcpmcppnpchohihcbdnojlgeel)

## TODO
- statistics
- translate in more languages
- test ;) 

## Versions
#### 0.4
- Support for OS X 10.8
- Better start and end game detection
- Support for arena decks !
- Add an option to remove cards instead of fade them (when you play the last)
- Export decks to text files
- Better language detection
- Import from [Hearthstats](https://hearthstats.net/)
- Import from [Hearthhead](http://www.hearthhead.com/) (all languages available)
- Import from [Hearthnews](https://hearthnews.fr/)
- Cards import optimizations
- Remove scrollbars

#### 0.3
- Deck manager ! Enjoy creating and editing deck directly from the app
- Correct a bug where the app keep asking about update
- Some corrections & optimisations
- German translation
- Netdeck import

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

And the resources came from [Hearthstone-Deck-Tracker](https://github.com/Epix37/Hearthstone-Deck-Tracker).

## Donations
Donations are always appreciated 

[![PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=bmichotte%40gmail%2ecom&lc=US&item_name=HSTracker&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted) 