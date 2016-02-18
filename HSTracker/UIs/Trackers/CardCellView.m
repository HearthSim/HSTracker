/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 15/02/16.
 */
#import "CardCellView.h"
#import "PlayCard.h"
#import "Card.h"
#import "ImageCache.h"
#import "Settings.h"
#import <QuartzCore/QuartzCore.h>

@interface CardCellView ()
{
  CALayer *cardLayer;
  CALayer *frameLayer;
  CALayer *gemLayer;
  CATextLayer *costLayer;
  CATextLayer *textLayer;
  CALayer *frameCountBox;
  CALayer *extraInfo;
  CALayer *flashLayer;
  CALayer *maskLayer;

  NSTrackingArea *trackingArea;
}
@end

@implementation CardCellView

- (instancetype)init
{
  if (self = [super init]) {
    self.wantsLayer = YES;

    self.layer.backgroundColor = [[NSColor clearColor] CGColor];

    // the layer for the card art
    cardLayer = [CALayer layer];
    [self.layer addSublayer:cardLayer];

    // the layer for the frame
    frameLayer = [CALayer layer];
    [self.layer addSublayer:frameLayer];

    // the layer for the gem art
    gemLayer = [CALayer layer];
    [self.layer addSublayer:gemLayer];

    costLayer = [CATextLayer layer];
    costLayer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
    [self.layer addSublayer:costLayer];

    textLayer = [CATextLayer layer];
    textLayer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
    [self.layer addSublayer:textLayer];

    frameCountBox = [CALayer layer];
    [self.layer addSublayer:frameCountBox];

    extraInfo = [CALayer layer];
    [self.layer addSublayer:extraInfo];

    // the layer for flashing the card on draw
    flashLayer = [CALayer layer];
    [self.layer addSublayer:flashLayer];

    maskLayer = [CALayer layer];
    maskLayer.contents = [ImageCache frameImageMask];
  }

  return self;
}

- (void)updateLayer
{
  Settings *settings = [Settings instance];
  float alpha;
  BOOL showAlpha;
  if (self.playerType == PlayerType_Player) {
    showAlpha = self.playCard.count == 0;
    if (!settings.inHandAsPlayed) {
      showAlpha = showAlpha && self.playCard.handCount <= 0;
    }

    alpha = (showAlpha) ? 0.4f : 1.0f;
  }
  else {
    alpha = self.playCard.count == 0 ? 0.4f : 1.0f;
  }

  float ratio;
  switch (settings.cardSize) {
    case CardSize_Small:
      ratio = (float) (KRowHeight / KSmallRowHeight);
          break;
    case CardSize_Medium:
      ratio = (float) (KRowHeight / KMediumRowHeight);
          break;
    case CardSize_Big:
    default:
      ratio = 1.0f;
          break;
  }

  // draw the card art
  cardLayer.contents = [ImageCache smallCardImage:self.playCard.card];
  float x = 104.0f / ratio;
  float y = 1.0f / ratio;
  float width = 110.0f / ratio;
  float height = 34.0f / ratio;
  cardLayer.frame = NSMakeRect(x, y, width, height);
  cardLayer.opacity = alpha;

  NSString *rarity = self.playCard.card.rarity;
  if (self.playCard.card.rarity && settings.showRarityColors) {
    gemLayer.contents = [ImageCache gemImage:rarity];
  }
  else {
    gemLayer.contents = nil;
  }
  x = 3.0f / ratio;
  y = 4.0f / ratio;
  width = 28.0f / ratio;
  height = 28.0f / ratio;
  gemLayer.frame = NSMakeRect(x, y, width, height);
  gemLayer.opacity = alpha;

  // draw the frame
  if (self.playCard.isStolen) {
    frameLayer.contents = [ImageCache frameDeckImage];
  }
  else {
    frameLayer.contents = [ImageCache frameImage:rarity];
  }
  x = 1.0f / ratio;
  y = 0.0f / ratio;
  width = 218.0f / ratio;
  height = 35.0f / ratio;
  NSRect frameRect = NSMakeRect(x, y, width, height);
  frameLayer.frame = frameRect;
  frameLayer.opacity = alpha;

  // print the card name
  NSColor *strokeColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:alpha];
  NSColor *foreground = [NSColor colorWithCalibratedRed:255 green:255 blue:255 alpha:alpha];
  if (self.playCard.handCount > 0 && self.playerType == PlayerType_Player) {
    foreground = [settings.flashColor colorWithAlphaComponent:alpha];
  }

  static NSFont *nameFont;
  if (settings.isCyrillicOrAsian) {
    nameFont = [NSFont fontWithName:@"NanumGothic" size:round(18.0f / ratio)];
  }
  else {
    nameFont = [NSFont fontWithName:@"Belwe Bd BT" size:round(15.0f / ratio)];
  }

  NSAttributedString *name = [[NSAttributedString alloc] initWithString:self.playCard.card.name attributes:@{
    NSFontAttributeName : nameFont,
    NSForegroundColorAttributeName : foreground,
    NSStrokeWidthAttributeName : settings.isCyrillicOrAsian ? @0 : @(-2),
    NSStrokeColorAttributeName : settings.isCyrillicOrAsian ? nil : strokeColor

  }];
  x = 38.0f / ratio;
  y = -3.0f / ratio;
  width = 174.0f / ratio;
  height = 30.0f / ratio;
  textLayer.frame = NSMakeRect(x, y, width, height);
  textLayer.opacity = alpha;
  textLayer.string = name;

  NSNumber *cardCost = self.playCard.card.cost;
  // print the card cost
  static NSFont *costFont = nil;
  costFont = [NSFont fontWithName:@"Belwe Bd BT" size:round(22.0f / ratio)];
  NSAttributedString *cost = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", cardCost]
                                                             attributes:@{
                                                               NSFontAttributeName : costFont,
                                                               NSForegroundColorAttributeName : foreground,
                                                               NSStrokeWidthAttributeName : @(-1.5),
                                                               NSStrokeColorAttributeName : strokeColor
                                                             }];
  x = ([cardCost integerValue] > 9 ? 6.0f : 13.0f) / ratio;
  y = -4.0f / ratio;
  width = 34.0f / ratio;
  height = 37.0f / ratio;

  costLayer.frame = NSMakeRect(x, y, width, height);
  costLayer.string = cost;

  // by default, we only show 2 or more
  int minCount = settings.showOneCard ? 1 : 2;

  if (self.playCard.count >= minCount || [self.playCard.card.rarity isEqualToString:@"legendary"]) {
    // add the background of the card count
    if (self.playCard.isStolen) {
      frameCountBox.contents = [ImageCache frameCountboxDeck];
    }
    else {
      frameCountBox.contents = [ImageCache frameCountbox];
    }
    x = 189.0f / ratio;
    y = 5.0f / ratio;
    width = 25.0f / ratio;
    height = 24.0f / ratio;
    frameCountBox.frame = NSMakeRect(x, y, width, height);

    if ((self.playCard.count > minCount && self.playCard.count < 9) && ![self.playCard.card.rarity isEqualToString:@"legendary"]) {
      // the card count
      extraInfo.contents = [ImageCache frameCount:@(self.playCard.count)];
    }
    else {
      // card is legendary (or count > 10)
      extraInfo.contents = [ImageCache frameLegendary];
    }
    x = 194.0f / ratio;
    y = 8.0f / ratio;
    width = 18.0f / ratio;
    height = 21.0f / ratio;
    extraInfo.frame = NSMakeRect(x, y, width, height);
  }
  else {
    extraInfo.contents = nil;
    frameCountBox.contents = nil;
  }
  frameCountBox.opacity = alpha;
  extraInfo.opacity = alpha;

  flashLayer.frame = self.bounds;
  maskLayer.frame = frameRect;
  flashLayer.mask = maskLayer;
}

- (void)flash
{
  flashLayer.backgroundColor = [[Settings instance].flashColor CGColor];
  CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fade.fromValue = @0.7;
  fade.toValue = @0.0;
  fade.duration = 0.5;

  fade.removedOnCompletion = NO;
  fade.fillMode = kCAFillModeBoth;

  [flashLayer addAnimation:fade forKey:@"alpha"];
}

// check mouse hover
- (void)ensureTrackingArea
{
  if (trackingArea == nil) {
    trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited
                                                  owner:self
                                               userInfo:nil];
  }
}

- (void)updateTrackingAreas
{
  [super updateTrackingAreas];

  [self ensureTrackingArea];

  if (![self.trackingAreas containsObject:trackingArea]) {
    [self addTrackingArea:trackingArea];
  }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
  if (self.delegate) {
    [self.delegate hover:self.playCard.card];
  }
}

- (void)mouseExited:(NSEvent *)theEvent
{
  if (self.delegate) {
    [self.delegate out:self.playCard.card];
  }
}
@end
