# HSTracker

HSTracker is a [Hearthstone](http://www.playhearthstone.com/) deck tracker for macOS 10.10+.

[![Build Status](https://travis-ci.org/HearthSim/HSTracker.svg?branch=master)](https://travis-ci.org/HearthSim/HSTracker)

### Community : 
- [![Join HearthSim #hstracker](https://img.shields.io/badge/discord-join%20chat-blue.svg)](https://discord.gg/PggsQ7F)
- [![Join the chat at https://gitter.im/HearthSim/HSTracker](https://badges.gitter.im/HearthSim/HSTracker.svg)](https://gitter.im/HearthSim/HSTracker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
- **HearthSim**: HSTracker is a [HearthSim](https://hearthsim.info) project. Come join us in #hearthsim on chat.freenode.net.
- **Twitter**: Follow [@hstracker_mac](https://twitter.com/hstracker_mac) for updates / questions :)

## Features
### Deck Tracker
![Deck Tracker](https://github.com/HearthSim/HSTracker/blob/master/hstracker.jpg)

### Deck Manager
![Deck Manager](https://github.com/HearthSim/HSTracker/blob/master/manager.jpg)

Is Blizzard okay with this ?
[Yes](https://twitter.com/bdbrode/status/511151446038179840)

Is it against the TOS ?
[No](https://twitter.com/CM_Zeriyah/status/589171381381672960)

## Installation
- Download the last version from [this page](https://hsdecktracker.net/hstracker/download/)
- Extract the archive
- Move _HSTracker.app_ to your _Applications_ directory
- Launch (make sure Hearthstone is not running when you first launch HSTracker) !
- Create a new deck from the Deck Manager or import it from [HearthPwn](http://www.hearthpwn.com), [Hearthstone-decks](http://www.hearthstone-decks.com), [Hearthstats](https://hearthstats.net), [Hearthhead](http://www.hearthhead.com/), [Hearthnews](http://www.hearthnews.fr/) and many more
- HSTracker can also auto-detect the deck you are playing with

## Versions
[Complete changelog is here](versions.markdown)

## Contribution
Feel free to fork and pull-request, as well as filling [new issues](https://github.com/HearthSim/HSTracker/issues)

In order to compile, you have to
- Clone the code.  Make a fork on github!

        git clone https://github.com/HearthSim/HSTracker.git

- Get / update swift dependencies using [Carthage](https://github.com/Carthage/Carthage/blob/master/README.md#installing-carthage)

        carthage update --platform osx

- Install [SwiftLint](https://github.com/realm/SwiftLint/blob/master/README.md#installation), example using Homebrew:

        brew install swiftlint

- Open the project in XCode and build
  - If you run into code signing errors, disable it by setting "Don't Code Sign" in the "Build Settings"

## Donations
Donations are always appreciated

[![PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=bmichotte%40gmail%2ecom&lc=US&item_name=HSTracker&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted)

## License

HSTracker is released under the [MIT license](LICENSE).
