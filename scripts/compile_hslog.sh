#! /bin/bash

if [ ! -d "Arcane-Tracker" ]
then
    git clone https://github.com/HearthSim/Arcane-Tracker Arcane-Tracker
fi

./Arcane-Tracker/gradlew -p Arcane-Tracker linkReleaseFrameworkMacosX64
