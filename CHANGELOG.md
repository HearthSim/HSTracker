# 2.6.4
## New
- Updated for Hearthstone 28.2.3
- Constructed: Improve importing of Whizbang decks
- Battlegrounds: Added support for Venomous and Reborn to the Last Known Board and Final Board features.
- Battlegrounds: Improved the behaviour of the Bob's Buddy panel at the end of a match.
## Fixes
- Constructed: Fixed an issue causing the popup with a link to the Mulligan guide sometimes incorrectly identifying the First/Coin state.
- Battlegrounds: Fixed an issue causing the hero picking overlay and popup not disappearing when HDT was started during the hero picking phase.
- Battlegrounds: Add missing Recurring Nightmare deathrattles for simulating combat results

# 2.6.3
## New
- Updated for Hearthstone 28.2.1
- Added Battlegrounds spells to the Battlegrounds minion list overlay!
## Fixes
- Fixed hero picking overlay not working
- Fixed an issue where the attack counters would not correctly handle Walking Mountain.
## Bob's Buddy
- Added support for spell triggers during combat (such as extra battlecries/deathrattles and start of combat effects).
- Fixed an issue where Audacious Anchor could crash the simulation.
- Fixed an issue where Battlecries from Rylak Metalhead were not simulated correctly after being triggered by Hawkstrider Herald.
- Fixed various simulation issues related to recently introduced and updated cards.

# 2.6.2
## New
- Updated for Hearthstone 28.2.0
- Added a spell school counter!
## Fixes
- Fix HSTracker stuck on splash screen if there is issue accessing remote config (issue #1332)
- Make flavor text black again
- The Battlegrounds minion overlay no longer shows minions from tavern tier 7 unless Secrets of Norgannon is active.
- Fixed an issue that caused the deck builder to not show appropriate multi-class cards.
## Bob's Buddy
- Added support for Fairy Tale Caroler's Battlecry (with Rylak Metalhead).
- There are likely still issues with some new cards in Bob's Buddy. We will update these in the coming days.

# 2.6.1
## New
- Updated for Hearthstone 28.0.3
- Added Excavate counters.
- Added support for a number of older cards.
## Fixes
- Fixed an issue where Sigils were not treated as spells.
- Fixed an issue where Snipe occasionally did not appear as a valid secret.
- Fixed an issue where Love Everlasting and similar cards were not treated as spells.
**Bob's Buddy**:
- Fixed an issue where Admiral Eliza Goreblade was not simulated correctly.

# 2.6.0
## New
- Updated for Hearthstone 28.0.0

# 2.5.12
## Fixes
- Fixed issue with corrupted battlegrounds opponent board on macOS Sonoma (issue #1329)

# 2.5.11
## New
- Improve secret handling across different formats
## Fixes
- Fix crash on app start up on some Macs after Xcode 15 upgrade (issue #1328)

# 2.5.10
## New
- Updated for Hearthstone 27.6.2
## Fixes
- Fixed an issue where the attack counters were not correctly handling Titans.
- Fixed an issue where Plagues were not correctly added back to the deck when Helya is in play.

# 2.5.9
## New
- Updated for Hearthstone 27.6.0
**Bob's Buddy**
- There are likely still issues with some new cards in Bob's Buddy. We will update these in the coming days.

# 2.5.8
## Fixes
- Fixed discovered secrets not being tracked (issue #1327)
- Fixed crashes due to interaction with Rylak (issue #1316)
**Bob's Buddy**
- Fixed an issue where Choral Mrrrglr was not simulated correctly.

# 2.5.7
## New
- Updated for Hearthstone 27.4.2
## Fixes
- Added Core Set Wandering Monster to list of secrets (PR #1326, thanks @IAmAdamTaylor)

# 2.5.6
## Fixes
- Fixed crash on startup introduced by version 2.5.5 (issue #1324)

# 2.5.5
## New
- Updated for Hearthstone 27.4.0
## Fixes
- Fixed an issue where randomly cast cards with Dredge could unintentionally reveal the affected cards.
- Fixed the C'Thun counter.
## Bob's Buddy
- Fixed an issue where Mannoroth and Murcules were not simulated correctly after being attacked.
- Fixed an issue where Frostwolf Lieutenant was simulated according to outdated card text.
- Fixed an issue where the Blessed or Blighted anomaly was not simulated correctly.

# 2.5.4
## New
- Updated for Hearthstone 27.2.2
## Fixes
- Fixed turn timer, card turn number, etc... not updating after previous change
- Fixed Tier 7 pre lobby showing as disabled
- Added missing Caverns of Time icon.
## Bob's Buddy
- Fixed an issue with a player having multiple Recurring Nightmares.
- Fixed various card issues related to cards updated in Hearthstone 27.2.2.

# 2.5.3
## New
**Bob's Buddy**
- Fixed further issues related to cards and mechanics added with Hearthstone 27.2.0.

# 2.5.2
## New
- Updated for patch 27.2.0

**Bob's Buddy**
- Added support for the new Minions and Anomalies.
- Added support for Murky.
- Fixed various issues related to cards and mechanics added with Hearthstone 27.2.0.
- Fixed an issue where Menagerie Mug, Menagerie Jug and Tide Oracle Morgl could crash the simulation.

# 2.5.1
## New
- Added support for HSReplay overall statistics
## Fixes
- Added missing Zombeees Hunter secret to list of available secrets
## Bob's Buddy
- Added support for Annihilan Battlemaster

# 2.5.0
## New
- Updated for Hearthstone 27.0.0

# 2.4.10
## Bob's Buddy
- Updated with support for the new Quests and Quest Rewards.
- Fixed an issue where the initial board state used for simulations could be slightly incorrect in some cases.
- We are actively investigating simulation issues and should have more improvements soon!

# 2.4.9
## Fixes
- Fixed secrets not showing in Twist mode
- Add support for Hidden Meaning

# 2.4.8
## New
- Updated for Hearthstone 26.6.2

# 2.4.7
## New
- Updated for Hearthstone 26.6.0

# 2.4.6
## New
- Updated for Hearthstone 26.4.3
## Fixes
- Improve handling of Hearthstone log directory

# 2.4.5
## New
- Updated for Hearthstone 26.4.0

## Bob's Buddy:

- Added support for many Battlecry interactions with Rylak Metalhead
- Fixed various issues related to cards and mechanics added with Hearthstone 26.2.0.

# 2.4.4
## New
- Updated for path 26.2.2

# 2.4.3
## New
- Updated for patch 26.2
**Notes**: BobsBuddy simulation still has some issues and unsupported interactions

# 2.4.2
## New
- Updated for patch 26.0.4

# 2.4.1
## New
- Updated for Year of the Wolf
- Added support for the majority of new cards.

# 2.4.0
## New
- Updated for patch 26.0.0

# 2.3.12
## Fixes
- Fixed clipping of Hero/Quest picking Tier 7 overlays on high resolutons (issue #1303)

# 2.3.11
## Fixes
- Fixed deck detection not working properly (issue #1304)

# 2.3.10
## New
- Updated for patch 25.6.0

# 2.3.9
## New
- Updated for patch 25.4.3
## Fixes
- Fixed placement of overlays on external monitors
- Added scaling to hero and quest picking overlays
- Fixed clipping of some battlegrounds overlays in fullscreen
- Improved checking for Hearhstone being fullscreen

# 2.3.8
## New
- Updated for patch 25.4
- Added Battlegrounds Session scaling
- Added Tier 7 overlays for Hero and Quest picking
- Added battlecry and deathrattle indicators into minions tier list
- Updated zh-Zans translations (thanks @moonfruit)
## Fixes
- Fixed simulation errors not accounging for Eternal Knight/Undead bonuses

# 2.3.7
## New
- Updated for patch 25.2.2
**Bob's Buddy**:
- Fixed various issues related to cards and mechanics added with Hearthstone 25.2.0.

# 2.3.6
## New
- Updated for patch 25.2.0
**Note:**
- There are likely still issues with some new cards in Bob's Buddy. We will update these in the coming days.

# 2.3.5
## Fixes
- Fix detection of decks containing signature cards

# 2.3.4
## New
- Updated for patch 25.0.4
- Improved adventure pre-built deck detection
## Fixes
- Fix revealing cards consumed by Souleater's Scythe
- Fix some collection upload issues

# 2.3.3
## Fixes
- Fixed deck detection with March of the Lich King cards (issue #1292)

# 2.3.2
## New
- Added support for March of the Lich King
## Fixes
- Fixed deck detection (issue #1291)

# 2.3.1
## Fixes
- Fixed Mercenaries visitor tasks
- Added work around for deck detection not working (issue #1291). This may not be perfect but will be improved

# 2.3.0
## New
- Updated for patch 25.0.0
## Fixes
- Updated how Khadgar interacts with Evil Twin in Bob's Buddy

# 2.2.10
## New
- Add support for new Mercenaries Visitor tasks
## Fixes
- Fixed various Bob's Buddy simulation issues related to Hearthstone 24.6.0.
- Fixed an issue in Bob's Buddy where Volatile Venom was not working correctly.
- Fixed an issue where Venomstrike Trap and Frozen Clone were not showing up in the secret tracker.

# 2.2.9
## New
- Updated for patch 24.6.0
## Fixes
- Correctly capture the board of Battlegrounds dead opponents

# 2.2.8
## New
- Updated for patch 24.4.3
- The opponent deck list can now be set in friendly games. This can be enabled for all game modes under Preferences > Opponent -> Enable setting opponent deck in non-friendly matches
- Deck importing can now be done using Clipboard instead of pasting
- Added support for Maw and Disorder secrets

# 2.2.7
## New
- Updated for patch 24.4

# 2.2.6
## New
- Updated for patch 24.2.2
- Updated zh-Hans translations (thanks @moonfruit)
## Fixes
- Fixes varios Bob's Buddy simulation issues, specially due to quest rewards not being tracked correctly

# 2.2.5
## Fixes
- Fixed various more Bob's Buddy simulation issues related to Hearthstone 24.2.0.

# 2.2.4
## New
- Added support for patch 24.2
## Fixes
- Prevent crash during log parsing under some rare condition and log it for further analysis
- Fixed an issue where it was revealed that the opponent was playing Renathal during mulligan.
**Notes**:
- There are likely still issues with some new cards in Bob's Buddy. We will update these in the coming days.
- Tooltips for vaious Battlegrounds cards may still be missing but should start appearing soon.

# 2.2.3
## New
- Added support for patch 24.0.3
- Added update reminder and notifications for future updates
## Fixes
- Fixed an issue where Secrets countered by Blademaster Okami were not handled correctly.

# 2.2.2
## Fixes
- Fixed bug importing deck lists from file
- Fixed Location cards not showing in the opponent tracker
- Fixed deck manager not showing card counts if scrollbar was visible
- Added code to prevent some crashes

# 2.2.1
## New
- Added support for Murder at Castle Nathria

# 2.2.0
## Fixes
- Updated for patch 24.0

# 2.1.14
## Fixes
- Fixed incorrect match result being recorded in deck statistics

# 2.1.13
## Fixes
- Miscellaneous performance improvements
- Fixed some rare crashes

# 2.1.12
## Fixes
- Fixed Mercenaries abilities not showing in matches versus AI (issue #1276)
- Fixed deck detection for Tavern Brawl
- Fixed some rare crashes

# 2.1.11
## New
- Add Abyssal counter
## Fixes
- Fixed turn timer and card drawn turn indicators not working

# 2.1.10
## Fixes
- Fixed detection of 40 card decks

# 2.1.9
## New
- Updated for patch 23.6
- Korean translation updates (thanks @kshired)
## Fixes
- Changed localization of Battlegrounds Session recap placement
- Several memory leak fixes
- Fixed several data races that led to crashes
- Some performance optimizations

# 2.1.8
## New
- Updated for patch 23.4.3
- Korean translation updates (thanks @kshired)
## Fixes
- Fixed Battlegrounds session recap not showing correctly
- Fixed Battlegorunds session recap gray window if all settings disabled (thanks @kshired)
- Fixed size of deck statistics tab to show all classes better (issue #1269)
- Fixed an issue where Mirror Entity was displayed in Standard games.
- Fixed an issue where information about cards discarded by Immolation was unintentionally revealed.

# 2.1.7
## New
- Updated for patch 23.4
- Improve Battlegrounds triples and upgrade history from HDT
- Show Battlegrounds Session recap final board age
## Fixes
- Fix for incorrectly showing session recap when not in Battlegrounds mode and Hide all when game in background is unchecked

## Fixes
# 2.1.6
## Fixes
- Fixed crash invoking BobsBuddy when Mono not available on the system

# 2.1.5
## New
- Added Battlegrounds session recap overlay (can be moved if not autopositioned/windows unlocked). Shows:
 * banned minions
 * start & current MMR or current MMR and change
 * latest 10 games
 * final board
- Added option to clear cached images and force a redownload
## Fixes
- Improved collection upload logic to avoid expired authorization issues

# 2.1.4
## New
- Updated for patch 23.2.2
- Updated Korean translations (thanks @kshired)
- Updated zh-Hans translations (thanks @moonfruit)
## Fixes
- Fixed collection upload issues introduced by version 2.1.3
- Fixed some crashes
- Fixed an issue where cards added to the top or bottom of the deck by From the Depths were not tracked correctly

# 2.1.3
## New
- Updated for patch 23.2
## Fixes
- Fixed an issue where Questline parts were counting towards the spell counter

# 2.1.2
## New
- Updated for patch 23.0.3
- Added support for top/bottom cards
- Updated Korean translations (thanks @rockmkd)
## Fixes
- Corrected mercenaries collection upload of portraits

# 2.1.1
## New
- Updated for Year of the Hydra
- Added support for the majority of new cards.

Dredge support coming soon!

# 2.1.0
## New
- Updated for patch 23.0

# 2.0.14
## New
- Updated for patch 22.6
## Fixes
- Show Toast notifications on the correct monitor
- Check Hearthstone window location has changed and update overlay if needed

# 2.0.13
## New
- Updated for patch 22.4.3
## Fixes
- Improvements to Toast notification appearing behind the notch (thanks @eraycantazeguney)
- Fix BG mulligan appearing on an already started match (thanks @eraycantazeguney)

# 2.0.12
## New
- Updated for patch 22.4
## Fixes
- Fixed buddies gained tracker when updating the current opponent board
- Fixed some more crashes

# 2.0.11
## New
- Updated for patch 22.2.2
- Added Battlegrounds buddies gained tracking (experimental)
## Fixes
- Hide player/opponent tracker during spectator mode for Battlegrounds
- Improve collection upload
- Fixed some crash cases
- Several Bob's Buddy fixes
- Fixed an issue where the indicator for how long Battlegrounds opponents have been dead was misaligned when Hero Skins were present in the lobby

# 2.0.10
## New
- Updated for patch 22.2
- Updated zh-Hans translations (thanks @moonfruit)

# 2.0.9
## New
- Added experimental support for Arena tier list generated from HSReplay data
- Require MacOS 10.12 or later again (may change in the near future)
## Fixes
- Fixed crash caused by missing synchronization of collection helper
- Resize card bar based on text length to avoid clipping of long card names
- Sort missing Battlegrounds tribe names
## Bob's Buddy
- Fixed an issue where Fish of N'Zoth was not copying all types of Deathrattles correctly.
- Fixed an issue where Cattlecarp of N'Zoth was not working.
- Fixed an issue where extra Deathrattles from Baron Rivendare would resolve too early.
- Fixed an issue where Avenge effects would resolve too early.
- Fixed an issue where golden Impulsive Trickster would always target the same minion twice.
- Fixed an issue where Grease Bot would buff the target before damage was dealt.
- Fixed an issue with the interaction between Greybough's Hero Power and Khadgar.
- Fixed an issue where Prestor's Pyrospawn woud trigger on non-dragon minions and itself.
- Fixed an issue where the 15 damage cap was still applied incorrectly in many cases when determining lethal rates.

# 2.0.8
## Fixes
- Notarize the application to allow it running
- Hide invisible board overlay if Flavor text setting is disabled (try to fix unable to click on minions)

# 2.0.7
## Fixes
- Fixed crash during Battlegrounds match

# 2.0.6
## New
- Updated for patch 22.0.2
## Bob's Buddy:
- Fixed various interactions with Peggy Brittlebone.
- Fixed an issue where various Avenge effects would trigger too often.
- Fixed an issue where Tamsin Roame's Hero Power could target the wrong minion.
- Fixed an issue where Impulsive Trickster would not pass on the correct amount of health when buffed.
- Fixed an issue where Sewer Rat was not considered to have a Deathrattle effect.
- Fixed an issue where the 15 damage cap was applied incorrectly in many cases when determining lethal rates.

# 2.0.5
## New
- Add support for Alterac Valley cards
- Show flavor text for cards on the board
## Fixes
- Track tradeable cards
- Fix secrets issues
- Fix data leak with Pack Mule
- Get right number of players on BG custom lobbies
- Hide turn timer in Mercenaries

# 2.0.4
## New
- Add support for patch 22.0
Note: HSTracker now requires MacOS 10.15 or later (Catalina)

# 2.0.3
## Fixes
- Fixed Bob's Buddy performance for Diablo
- Fixed Bob's Buddy speed
- Fixed Bob's Buddy performance when two players with secrets enter combat
- Support the new Alterac Valley cards
- Fix Mercenaries Task view when description is long

# 2.0.2
## New
- Add support for patch 21.8
- Add mercenaries abilities overlay
## Fixes
- Removed timeout from Battlegrounds Hero selection panel
- Fixed mercenaries tasks showing last completed task

# 2.0.1
## New
- Add Mercenaries tasks overlay
- Battlegrounds support for multiple Sneeds hero powers
## Fixes
- Fixed Bob's Buddy's interaction with Diablo

# 2.0.0
## New
- Add Mercenaries ability hover (more to come soon)
- Add support for patch 21.6
## Fixes
- Card hover only shows card, no text
- Fixed crash during Book of Heroes

# 1.9.16
## New
- Add support for patch 21.4
- Mercenaries support coming in near future
## Fixes
- Don't show trackers for during mercenaries mode

# 1.9.15
## New
- Enhanced Korean translations (thanks @rockmkd)
- Add support for patch 21.3

# 1.9.14
## Fixes
- Various BobsBuddy fixes and performance improvements

# 1.9.13
## New
- Add support for patch 21.2
- Enhanced zh-Hant translations (thanks @Fidetro)
- Updated zh-Hans translations (thanks @moonfruit)

# 1.9.12
## New
- Add support for patch 21.0.3
## Fixes
- Don't count dormant minion attack (issue #1234)
- Fixed an issue where the battlegrounds overlay would not work with hero skins in some cases
- Fixed an issue where questlines were not considered quests
- Fixed an issue where HST did not count games played against an opponent with Maestra as games against a Rogue
- Add support for Judgement of Justice

# 1.9.11
## New
- Add support for patch 21.0
- Add United in Stormwind card set
## Fixes
- Fix problem with replay upload after disconnect

# 1.9.10
## New
- Add support for patch 20.8
- Add BobsBuddy support for Akazamarak
## Fixes
- Fix unavailable battlegrounds races for new patch

# 1.9.9
## Fixes
- Fix only first game replay uploading (issue #1231)

# 1.9.8
## New
- Add support for patch 20.4.2
## Fixes
- Attempt to fix bug where replay sometimes doesn't upload

# 1.9.7
## New
- Added missing card set icons
- Add support for patch 20.4

# 1.9.6
## Fixes
- Fix card database for missing cards

# 1.9.5
## New
- Add Libram counter
- Track Efficient Octobot cost reduction
- Increased size of floating hover image
## Fixes
- Remove Rigged Faire Game secret when opponent loses armor
- Fix memory growth due to spectator improvements (issue #1207)
- Fix secret helper in arena (issue #1222)
- Exclude BG neutral minions that are tribe specific
- Fix multi-desktop overlay for battlegrounds (issue #1225 - thanks @chao2zhang)

# 1.9.4
## New
- Add support for patch 20.2.2
- Improved support for spectator mode, including Battlegrounds
- Updated zh-Hans translation (thanks @moonfruit)
## Fixes
- Fixed handling of log lines with Unicode characters

# 1.9.3
## New
- Add support for patch 20.2.0
- Show deck mulligan for constructed matches
- Added option to not display BG hero comparison
- Improved background display of BG warband
- Support deleting multiple decks in the Deck Manager
- Updated zh-Hans translation (thanks @moonfruit)
- Updated icons with Big Sur guidelines (thanks @stevenjoezhang)
## Fixes
- Fix secret helper window display on Big Sur (issue #1214)
- Fix BG opponent dead tracker when Overlord Saurfang is in the lobby
- Fix some more crashes in some rare occasions
- Fix tracking for Core Jaraxxus not updating deck tracker (issue #1219)
- Fix rare bug where deck has cards out of order
 
# 1.9.2
## New
- Add support for patch 20.0.2
## Fixes
- Improve collection upload to be more reliable (issue #1189)
- Fix secret handler showing classic secrets in standard (issue #1216)
- Fix crash when Hearthstone is stopped and log reader is stopping
- Fix logic for Adventure restart
- Fix secret handling for Oasis Ally and Rigged Faire Game
- Fix tracking of Rank spells and Transfer Student
- Fix missing synchronization during deck list update
- Fix Far Sight drawn cards not tracking properly in Classic mode

# 1.9.1
## New:
- Improved secret handling for different modes
- Add Barrens known card ids
- Improve deck detection logic
- Add support for Book of Mercenaries
## Fixes
- Fixed Core set cards causing deck detection failure
- Fixed diamond cards causing deck deteciton failure
- Fixed some more reported potential crash locations

# 1.9.0
## New:
- Add tavern upgrade and triple history
- Improve hover of BG cards from tier window
- Ask permission to send crash reports
- Add Forged in the Barrens card set
- Log memory usage periodically
- Add support for patch 20.0
- Add support for Classic mode
## Fixes
- Fix tracker positions on Big Sur and fullscreen (issue #1204)
- Fix dead for turn tracking for 8th place
- Fix some crashes
- Fix some memory leaks

# 1.8.1
## New:
- Improved deck manager display
- Add dead for turn tracking for Battlegrounds
- Improved zh-Hans translation (thanks @moonfruit)
- Improved Russian translation (thanks @4llower)
## Fixes
- Improved experience tracker location & size
- Fix for Book of Heroes: Anduin
- Fix experience counter showing at end of BG match before final combat
- Fix graveyard missing in fullscreen (issue #973)
- Retry collection upload after failure with new token
- Fix Shenanigans handling
- Fix C'thun the Shattered cards
- Fix for Bobs Buddy showing incorrectly if "Hide while in background" was unchecked (issue #1201)

# 1.8.0
## New:
- Updated for patch 19.4
- Add experience tracker
- Duels support
- Improved Battlegrounds Tier display
- Improved Adventure support, including Book of Heroes
## Fixes:
- Fix issue where players could occasionally see when their opponent drew a card created by C'thun the Shattered
- Hide Secret Helper during Battlegrounds
- Fix bug when importing deck code strings

# 1.7.8
## New:
- Updated for patch 19.2
- Improve function around Dungeon Runs and Duels

# 1.7.7
## New:
- Add more tracking of 'created by' effects
- Add option to hide minion tiers in battlegrounds

## Fixes:
- Improve speed and memory usage
- Fixes issues where spells wouldn't track for the player
- Fixed issue where Bob's Buddy occasionally wouldn't detect Lich King hero powers

# 1.7.6
## New:
- Improve last seen board
- Catch errors running battlegrounds simulation
## Fixes:
- Prevent crash retrieving Battlegrounds available races

# 1.7.5
## New:
- Updated for patch 18.6.1 (fixed)

# 1.7.4
## New: 
- Updated for patch 18.6.1

# 1.7.3
## New:
- Add tooltip for source of created cards
- Fix crash when uploading certain replays
- Add support for best heroes by minion type breakdown in battlegrounds

# 1.7.2
## New:
- Add average damage to Bob's Buddy
- Add turn counter for Battlegrounds
- Hide player's deck in Battlegrounds

# 1.7.1
## New:
- Updated for patch 18.4.2

# 1.7.0
## New:
- Bob's Buddy
- Updated for Elementals

# 1.6.38
## New:
- Updated for patch 18.0.2

# 1.6.37
## New:
- Updated for patch 18.0
- Filter out minions not available in Battlegrounds (Thanks @fmoraes74)
- Hide deck overlay during Battlegrounds games (Thanks @fmoraes74)

# 1.6.36
## New:
- Updated for patch 17.6

# 1.6.35
## New:
- Battlegrounds pirates

# 1.6.34
## Fixes:
- Battlegrounds MMR

# 1.6.33
## Fixes:
- Upload Battlegrounds Games

# 1.6.32
## Fixes:
- Enable memory reading again. Fixes Games and Collection upload.

# 1.6.31
## Fixes:
- Make basic tracking work again after patch 17.2. Game and Collection upload are not working yet.

# 1.6.30
## New:
- Battlegrounds: added a Toast to compare Heroes
## Improved:
- Faster launch
- Smaller collection upload Toast

# 1.6.29
## Fixes:
- Added Dirty Trick.

# 1.6.28
## Fixes:
- Added Ashes of Outlands secrets.

# 1.6.25
## Fixes:
- Fix a crash at startup.

# 1.6.24
## Fixes:
- Fix a crash when the opponent plays a secret.

# 1.6.23
## Fixes:
- Fix collection upload not disappearing.

# 1.6.22
## New:
- Initial support for Demon Hunter.

# 1.6.21
## New:
- Adapt for the new ladder system.

# 1.6.20
## Fixes:
- Fix a crash on collection upload.

# 1.6.19
## Fixes:
- Fix a crash on collection upload. 

# 1.6.18
## New:
- Support for patch 16.6

# 1.6.17
## New:
- Battlegrounds Dragons

# 1.6.16
## New:
- Updated card database

# 1.6.15
## New:
- Support for Galakrond's awakening

# 1.6.14
## New:
- Galakrond counter

# 1.6.13
## Fixes:
- Do not try to upload the collection if the setting is not enabled

# 1.6.12
## New:
- Battlegrounds minion tiers are now visible during a Battlegrounds game

# 1.6.11
## Fixes:
- Improve collection upload (https://github.com/HearthSim/HSTracker/issues/1101)
- Fixed battlegrounds overlay in windowed mode (https://github.com/HearthSim/HSTracker/issues/1095)

# 1.6.10
## New:
- Descent of Dragons!

# 1.6.9
## New:
- Battlegrounds support: Hovering an opponent in the sidebar will now display their last known board state.
- Better collection upload dialog.

# 1.6.8
## New:
- Sathrovarr support

# 1.6.6
## New:
- Update for Hallow's end

# 1.6.4
## New:
- Update for 2019-08-26 nerfs
- Sign the app with a "Developer ID" certificate (https://github.com/HearthSim/HSTracker/issues/1018 and https://github.com/HearthSim/HSTracker/issues/1078) 
- Add support for tracking uldmu cards

# 1.6.3
## New:
- Added support for Saviors of Uldum

# 1.6.2
## Fixes:
- Fixed secret tracker is lagging  (https://github.com/HearthSim/HSTracker/issues/972 and https://github.com/HearthSim/HSTracker/issues/994)
- Fixed window positioning on MacOS Catalina  (https://github.com/HearthSim/HSTracker/issues/1071)

# 1.6.1
## New:
- Added support for Patch 14.6
## Fixes:
- Fixed Rat Trap and Hidden Wisdom (https://github.com/HearthSim/HSTracker/issues/1065#event-2449704550)

# 1.6.0
## Fixes:
- Fixed rank detection not working since patch 14.4.0.31268 (https://github.com/HearthSim/HSTracker/issues/1063)

# 1.5.9
## New:
- Added support for Patch 14.4
## Fixes:
- Hopefully fix a random crash happening in 1.5.8 (https://github.com/HearthSim/HSTracker/issues/1054)

# 1.5.8
## Fixes:
- Collection will update endlessly (https://github.com/HearthSim/HSTracker/issues/1045)

# 1.5.7
## Fixes:
- Crash fixes

# 1.5.6
## New:
- Added support for Rise of the shadows

# 1.5.5
## Fixes:
- Updated card data for the latest patch
- Display card art on mouse hover
- Fixed 'UNKNOWN HUMAN' opponent name
- Whizbang support
- Fix rank upload

# 1.5.4
## Fixes:
- Updated card data for the latest patch
- Fixed card overlays for the dark theme in OSX Mojave

# 1.5.3
## Fixes:
- Added missing secrets

# 1.5.2a
## Fixes:
- Fixed a card loading bug

# 1.5.2
## New:
- Added support for the Rastakhan's Rumble expansion

# 1.5.1c
## Fixes:
- Fixed hsreplay.net oauth address
- Fixed a bug that blocked collection upload in certain situations

# 1.5.1
## New:
- Added Collection uploading to HSReplay.net
- Added more translations

## Fixes:
- Fixed a small bug with Rat Trap
- Minor bugfixes

# 1.5.0
## New:
- Added support for The Boomsday Project

# 1.4.4
## New:
- Updated card data for patch 11.4.0.25252.
- Added support for Chameleos

## Fixes:
- Fixed arena card reading

# 1.4.3
## Fixes:
- Fixed issues with Taverns of Time cards

# 1.4.2
## New:
- Updated card data for patch 11.2.0.24769.

# 1.4.1
## Fixes:
- Fixed issues with Witchwood cards

# 1.4.0
## Fixes:
- Fixed broken updater
- Fixed cardclass parsing (kudos dlackty)

## New:
- Added support for Witchwood cards
- Removed Track-o-bot support

# 1.3.5
## Fixes:
- Fixed issues introduced by the latest Hearthstone patch
- Removed deck to Hearthstone automated export

## New:
- Added new arena-only cards
- Added Hand of Salvation to secret tracker

# 1.3.4
## Fixes:
- Fixed an error that caused the tracker to stop working when the opponent was invisible
 
## New:
- Added Kingsbane and Weasel Tunneler interactions

# 1.3.3
## New:
- Updated card data to the 10.2 patch

# 1.3.2
## Fixes:
- Secret tracker disappears correctly
- Fixed anomaly with user settings (High Sierra users please update to 10.13.2)
- Fixed crashes related to notification center

## New:
- Deck Manager menu item in the dock menu
- Dungeon run support
- Removed website deck importers
- Added zh-TW translations (kudos @WenTsai)
- Added quick preferences access to the dock menu

# 1.3.1
## Fixes:
- Correct build number
- Deck is now correctly detected in friendly games

# 1.3.0
## New:
- Updated for Kobolds and Catacombs
- Added KotFT Deathknight hero power damages to boarddamage counter
- Opponent tracker can now be auto-positioned below opponent's name to prevent coverage

## Fixes:
- Fixed secret tracker not hiding excluded cards
- Tracking in spectator mode is now disabled by default but can be enabled in the preferences
- Board damage calculator only adds hero power if player has enough mana
- Fixed import from Hearthstonetopdecks
- Fixed statistics table sorting crash

# 1.2.4
## Fixes:
- Fix an issue with auto-update

# 1.2.3
## Fixes:
- Update cards for Hearthstone 9.4.0.22115

# 1.2.2
## New:
- Updated for Hearthstone 9.4.0.22115

## Fixes:
- Fixed the missing indicator for the 2nd card with lower value on arena drafting
- Fixed a bug where hero cards were not tracked properly
- Fixed an issue where HSTracker could not track Hearthstone if it was installed not in the Applications folder
- Refactored the secret manager

# 1.2.1
## New:
- Export deckstring from the deck manager

## Fixes:
- HSTracker is now compatible with 64-bits Hearthstone
- Various fixes

# 1.2.0
## New:
- Updated for Hearthstone 9.2.0.21517

# 1.1.0
## New:
- Support for Knights of the Frozen Throne

# 1.0.3
## Fixes:
- Fixed an error where corrupted decks could crash HSTracker

## Changes:
- Update german localization

# 1.0.2
## Fixes:
- Fixed a crash when the deck manager UI tries to save a new deck
- Getaway Kodo is correctly handled by secret helper

## New:
- Import a deck into HSTracker with the new deckstring

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
