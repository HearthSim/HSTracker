

# Clone translations
git clone -b macos-test https://github.com/HearthSim/HDT-Localization Translations/

# Download cards
./scripts/cards_download.sh

git clone -b macos-test https://github.com/HearthSim/Arcane-Tracker Arcane-Tracker

./Arcane-Tracker/gradlew -p Arcane-Tracker linkReleaseFrameworkMacosX64
