#! /bin/bash

if [ ! -d "Arcane-Tracker" ]
then
    git clone https://github.com/HearthSim/Arcane-Tracker Arcane-Tracker
fi

./Arcane-Tracker/gradlew -p Arcane-Tracker linkReleaseFrameworkMacosX64
#./Arcane-Tracker/gradlew -p Arcane-Tracker linkDebugFrameworkMacosX64
#rm -rf Arcane-Tracker/kotlin-hslog/build/bin/macosX64/releaseFramework/
#cp -a Arcane-Tracker/kotlin-hslog/build/bin/macosX64/debugFramework/ Arcane-Tracker/kotlin-hslog/build/bin/macosX64/releaseFramework
