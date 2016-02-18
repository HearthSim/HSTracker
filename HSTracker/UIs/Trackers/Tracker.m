//
//  Tracker.m
//  HSTracker
//
//  Created by Benjamin Michotte on 15/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import "Tracker.h"
#import "PlayCard.h"
#import "Card.h"
#import "CardCellView.h"
#import "CardSize.h"
#import "Settings.h"
#import "Hearthstone.h"
#import "HandCountPosition.h"

@interface Tracker () <NSTableViewDataSource, NSTableViewDelegate, CardCellHover>

@property(weak) IBOutlet NSTableView *table;
@property(weak) IBOutlet NSTableColumn *tableColumn;
@property(nonatomic) BOOL gameEnded;
@property(nonatomic,strong) Card *heroCard;

@end

@implementation Tracker

- (instancetype)init
{
  return [self initWithWindowNibName:@"Tracker"];
}

- (void)windowDidLoad
{
  [super windowDidLoad];

  self.gameEnded = NO;

  float width;
  Settings *settings = [Settings instance];
  switch (settings.cardSize) {
    case CardSize_Small:
      width = (float) KSmallFrameWidth;
          break;
    case CardSize_Medium:
      width = (float) KMediumFrameWidth;
          break;
    case CardSize_Big:
    default:
      width = KFrameWidth;
          break;
  }

  [self.window setFrame:NSMakeRect(0, 0, width, 200) display:YES];
  self.window.contentMinSize = NSMakeSize(width, 200);
  self.window.contentMaxSize = NSMakeSize(width, NSHeight(NSScreen.mainScreen.frame));

  self.window.opaque = NO;
  self.window.hasShadow = NO;
  self.window.backgroundColor = [NSColor clearColor];

  BOOL locked = settings.windowsLocked;
  if (locked) {
    self.window.styleMask = NSBorderlessWindowMask;
  }
  else {
    self.window.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask;
  }
  self.window.ignoresMouseEvents = locked;
  self.window.acceptsMouseMovedEvents = YES;

  if ([Hearthstone instance].isHearthstoneActive) {
    self.window.level = NSScreenSaverWindowLevel;
  }
  self.table.delegate = self;
  self.table.dataSource = self;
  self.table.intercellSpacing = NSMakeSize(0, 0);

  self.table.backgroundColor = [NSColor clearColor];
  self.table.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  self.tableColumn.width = NSWidth(self.table.bounds);
  self.tableColumn.resizingMask = NSTableColumnAutoresizingMask;

  self.cards = [NSMutableArray array];
  /*PlayCard *playCard = [[PlayCard alloc] init];
  playCard.count = @2;
  playCard.card = [Card byId:@"GVG_078"];
  [self.cards addObject:playCard];

  playCard = [[PlayCard alloc] init];
  playCard.count = @1;
  playCard.card = [Card byId:@"GVG_110"];
  [self.cards addObject:playCard];*/

  [self.table reloadData];
}

#pragma mark - NSTableViewDelegate / NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  NSInteger count = [self.cards count];

  /*if ([Settings instance].handCountWindow == HandCountPosition_Tracker) {
    count += 1;
  }

  if (self.playerType == PlayerType_Opponent && self.gameEnded) {
    count += 1;
  }*/

  return count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  PlayCard *playCard = self.cards[(NSUInteger) row];
  if (playCard) {
    CardCellView *cell = [[CardCellView alloc] init];
    cell.playCard = playCard;
    cell.playerType = PlayerType_Player;
    cell.delegate = self;

    if (playCard.hasChanged) {
      playCard.hasChanged = NO;
      [cell flash];
    }
    return cell;
  }
  else {
    //cell = CountTextCellView.new
    //cell.text = @count_text
  }

  return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  /*if (Configuration.hand_count_window == :tracker && row >= @playing_cards.count) {
  case Configuration.card_layout
    when :small
    ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
  when :medium
  ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
  else
  ratio = 1.0
  end
  50.0 / ratio
  }
  else {*/
  switch ([Settings instance].cardSize) {
    case CardSize_Small:
      return KSmallRowHeight;
    case CardSize_Medium:
      return KMediumRowHeight;
    case CardSize_Big:
    default:
      return KRowHeight;
  }
  //}
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
  return NO;
}

#pragma mark - CardCellHover

- (void)hover:(Card *)card
{
  //DDLogInfo(@"hovering %@", card);
}

- (void)out:(Card *)card
{
  //DDLogInfo(@"out %@", card);
}

#pragma mark - Game

- (void)gameStart
{
  self.gameEnded = NO;
  self.cards = [NSMutableArray array];
  [self.table reloadData];
}

- (void)gameEnd
{
  self.gameEnded = YES;
}

- (void)setHero:(Card *)card
{
  self.heroCard = card;
  if (self.heroCard && self.heroCard.playerClass && ![Settings instance].fixedWindowNames) {
    [self.window setTitle:NSLocalizedString(self.heroCard.playerClass, nil)];
  }
}

- (void)setName:(NSString *)name
{

}

- (void)joust:(Card *)card turn:(NSInteger)turn
{

}

- (void)getToDeck:(Card *)card turn:(NSInteger)turn
{

}

- (void)secretTrigger:(Card *)card turn:(NSInteger)turn
{

}

- (void)turnStart:(NSInteger)number
{

}

- (void)get:(Card *)card turn:(NSInteger)turn
{

}

- (void)backToHand:(Card *)card turn:(NSInteger)turn
{

}

- (void)playToDeck:(Card *)card turn:(NSInteger)turn
{

}

- (void)play:(Card *)card from:(NSInteger)from turn:(NSInteger)turn
{
  BOOL found = NO;
  for (PlayCard *playCard in self.cards) {
    if ([playCard.card.cardId isEqualToString:card.cardId]) {
      playCard.count += 1;
      found = YES;
      break;
    }
  }

  if (!found) {
    PlayCard *playCard = [[PlayCard alloc] init];
    playCard.count = 1;
    playCard.card = card;
    [self.cards addObject:playCard];
  }

  [self.table reloadData];
}

- (void)handDiscard:(Card *)card from:(NSInteger)from turn:(NSInteger)turn
{

}

- (void)secretPlayed:(Card *)card from:(NSInteger)from turn:(NSInteger)turn fromDeck:(BOOL)deck
{

}

- (void)mulligan:(Card *)card from:(NSInteger)from
{

}

- (void)draw:(Card *)card turn:(NSInteger)turn
{

}

- (void)removeFromDeck:(Card *)card turn:(NSInteger)turn
{

}

- (void)deckDiscard:(Card *)card turn:(NSInteger)turn
{

}

- (void)deckToPlay:(Card *)card turn:(NSInteger)turn
{

}
@end
