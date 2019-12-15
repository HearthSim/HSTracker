# Clone translations
git clone -b macos-test https://github.com/HearthSim/HDT-Localization Translations/

# Download cards
./scripts/cards_download.sh

# Clone Arcane-Tracker for kotlin-hslog
git clone https://github.com/HearthSim/Arcane-Tracker Arcane-Tracker

# build the framework file
./Arcane-Tracker/gradlew -p Arcane-Tracker linkReleaseFrameworkMacosX64
