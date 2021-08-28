#! /bin/bash

if [ ! -d "Arcane-Tracker" ]
then
    git clone https://github.com/HearthSim/Arcane-Tracker Arcane-Tracker
fi

./Arcane-Tracker/gradlew -p Arcane-Tracker linkReleaseFrameworkMacosX64 -Dorg.gradle.jvmargs=-Xmx2g
rm -rf downloaded-frameworks/kotlin_hslog/kotlin_hslog.framework
cp -a Arcane-Tracker/kotlin-hslog/build/bin/macosX64/releaseFramework/kotlin_hslog.framework downloaded-frameworks/kotlin_hslog/
cp -a Arcane-Tracker/kotlin-hslog/build/bin/macosX64/releaseFramework/kotlin_hslog.framework.dSYM downloaded-frameworks/kotlin_hslog/


#./Arcane-Tracker/gradlew -p Arcane-Tracker linkDebugFrameworkMacosX64
#rm -rf Arcane-Tracker/kotlin-hslog/build/bin/macosX64/releaseFramework/
#cp -a Arcane-Tracker/kotlin-hslog/build/bin/macosX64/debugFramework/ Arcane-Tracker/kotlin-hslog/build/bin/macosX64/releaseFramework
