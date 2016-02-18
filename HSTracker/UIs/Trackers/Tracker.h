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

@class Card;

@interface Tracker : NSWindowController

@property(nonatomic) EGameMode gameMode;
@property(nonatomic) PlayerType playerType;
@property(nonatomic) NSMutableArray *cards;

- (void)gameStart;

- (void)gameEnd;

- (void)setHero:(Card *)card;

- (void)setName:(NSString *)name;

- (void)joust:(Card *)card turn:(NSInteger)turn;

- (void)getToDeck:(Card *)card turn:(NSInteger)turn;

- (void)secretTrigger:(Card *)card turn:(NSInteger)turn;

- (void)turnStart:(NSInteger)number;

- (void)get:(Card *)card turn:(NSInteger)turn;

- (void)backToHand:(Card *)card turn:(NSInteger)turn;

- (void)playToDeck:(Card *)card turn:(NSInteger)turn;

- (void)play:(Card *)card from:(NSInteger)from turn:(NSInteger)turn;

- (void)handDiscard:(Card *)card from:(NSInteger)from turn:(NSInteger)turn;

- (void)secretPlayed:(Card *)card from:(NSInteger)from turn:(NSInteger)turn fromDeck:(BOOL)deck;

- (void)mulligan:(Card *)card from:(NSInteger)from;

- (void)draw:(Card *)card turn:(NSInteger)turn;

- (void)removeFromDeck:(Card *)card turn:(NSInteger)turn;

- (void)deckDiscard:(Card *)card turn:(NSInteger)turn;

- (void)deckToPlay:(Card *)card turn:(NSInteger)turn;
@end
