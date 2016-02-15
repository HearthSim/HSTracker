//
//  Tracker.m
//  HSTracker
//
//  Created by Benjamin Michotte on 15/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import "Tracker.h"

#define KFrameWidth 220.0
#define KFrameHeight 700.0
#define KRowHeight 37.0

#define KMediumRowHeight 29.0
#define KMediumFrameWidth (KFrameWidth / KRowHeight * KMediumRowHeight)

#define KSmallRowHeight 23.0
#define KSmallFrameWidth (KFrameWidth / KRowHeight * KSmallRowHeight)

@interface Tracker () <NSTableViewDataSource, NSTableViewDelegate>

@property(weak) IBOutlet NSTableView *table;
@property(weak) IBOutlet NSTableColumn *tableColumn;
@end

@implementation Tracker

- (instancetype)init
{
  return [self initWithWindowNibName:@"Tracker"];
}

- (void)windowDidLoad
{
  [super windowDidLoad];


  float width;
  // Todo config
  /*switch (Settings.card_layout) {
    case small
      width = KSmallFrameWidth
    case medium
      width = KMediumFrameWidth
    default
    */
  width = KFrameWidth;
  //end
  [self.window setFrame:NSMakeRect(0, 0, width, 200) display:YES];
  self.window.contentMinSize = NSMakeSize(width, 200);
  self.window.contentMaxSize = NSMakeSize(width, NSHeight(NSScreen.mainScreen.frame));

  // TODO
  self.window.opaque = NO;
  self.window.hasShadow = NO;
  self.window.backgroundColor = [NSColor clearColor];

  // Todo CONFIG
  BOOL locked = YES;
  if (locked) {
    self.window.styleMask = NSBorderlessWindowMask;
  }
  else {
    self.window.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask;
  }
  self.window.ignoresMouseEvents = YES; // Settings.locked
  self.window.acceptsMouseMovedEvents = YES;

  self.table.delegate = self;
  self.table.dataSource = self;
  self.table.intercellSpacing = NSMakeSize(0, 0);

  self.table.backgroundColor = [NSColor clearColor];
  self.table.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  self.tableColumn.width = NSWidth(self.table.bounds);
  self.tableColumn.resizingMask = NSTableColumnAutoresizingMask;

  NSLog(@"coucou");
}

#pragma mark - NSTableViewDelegate / NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return nil;
}

#pragma mark - Game
- (void)gameStart
{

}

- (void)gameEnd
{

}
@end
