//
//  Tracker.h
//  HSTracker
//
//  Created by Benjamin Michotte on 15/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GameMode.h"
#import "Game.h"

@interface Tracker : NSWindowController

@property(nonatomic) GameMode gameMode;
@property(nonatomic) PlayerType playerType;

- (void)gameStart;

- (void)gameEnd;
@end
