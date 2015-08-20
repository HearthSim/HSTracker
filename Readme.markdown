# HSTracker

HSTracker is a [Hearthstone](http://www.playhearthstone.com/) deck tracker for Mac OsX 10.8+.

Don't forget to follow [@hstracker_mac](https://twitter.com/hstracker_mac) for updates / questions :)

### Deck Tracker
![Deck Tracker](https://github.com/bmichotte/HSTracker/blob/master/hstracker.jpg)

### Deck Manager
![Deck Manager](https://github.com/bmichotte/HSTracker/blob/master/manager.png)

Is Blizzard okay with this ?
[Yes](https://twitter.com/bdbrode/status/511151446038179840)

Is it against the TOS ?
[No](https://twitter.com/CM_Zeriyah/status/589171381381672960)

## Installation
- Download the last version from [this page](https://rink.hockeyapp.net/apps/f38b1192f0dac671153a94036ced974e)
- Extract the archive
- Move _HSTracker.app_ to your _Applications_ directory
- Launch (make sure Hearthstone is not running when you first launch HSTracker) !
- Create a new deck from the Deck Manager or import it from [HearthPwn](http://www.hearthpwn.com) (deck and deckbuilder), [Hearthstone-decks](http://www.hearthstone-decks.com), [Hearthstats](https://hearthstats.net), [Hearthhead](http://www.hearthhead.com/) (all languages), [Hearthnews](http://www.hearthnews.fr/) or using [Netdeck](https://chrome.google.com/webstore/detail/netdeck/lpdbiakcpmcppnpchohihcbdnojlgeel)
- Starting of version 0.5, you can move/resize your windows and then lock them through the preferences panel. You can also change the transparency of the windows in the preferences.

## Update
As of 0.12, HSTracker will now prompt you to auto-update itself as soon as a new version is released. You can also check for new versions in _HSTracker menu_ -> _Check for update_

[![Build Status](https://travis-ci.org/bmichotte/HSTracker.svg?branch=master)](https://travis-ci.org/bmichotte/HSTracker)

## TODO
- translate in more languages
- test ;)

## Versions
[Complete changelog is here](versions.markdown)

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
