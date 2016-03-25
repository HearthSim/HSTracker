//
//  HSTracker-Bridging-Header.h
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#ifndef HSTracker_Bridging_Header_h
#define HSTracker_Bridging_Header_h

#define LOG_LEVEL_DEF ddLogLevel

#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

#import <MASPreferences/MASPreferencesViewController.h>
#import <JNWScrollView/JNWScrollView.h>
#import <JNWCollectionView/JNWCollectionView.h>

#import <HockeySDK/HockeySDK.h>

#endif /* HSTracker_Bridging_Header_h */
