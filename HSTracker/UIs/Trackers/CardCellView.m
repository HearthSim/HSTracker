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
}
@end

@implementation CardCellView

- (instancetype)init
{
  if (self = [super init]) {
    self.wantsLayer = YES;

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
    maskLayer.contents = [[NSImage alloc] initWithContentsOfFile:[
      [[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"frame_mask.png"]];
  }

  return self;
}


- (void)updateLayer
{
  //[super updateLayer];
  float alpha;
  BOOL showAlpha;
  if (self.playerType == Player) {
    showAlpha = [self.playCard.count isEqualToNumber:@0];
    //if (!Configuration.in_hand_as_played) {
    //showAlpha = showAlpha && card.hand_count <= 0
    //}

    alpha = (showAlpha) ? 0.4f : 1.0f;
  }
  else {
    alpha = [self.playCard.count isEqualToNumber:@0] ? 0.4f : 1.0f;
  }

  /*layout = Configuration.card_layout
  if card_size
      layout = card_size
    end*/
    float ratio = 1.0f;
  /*
  = case layout
    when :small
    TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
  when :medium
  TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
  else
  1.0
  end*/
  // draw the card art
  NSString *image = [[[self.playCard.card.englishName lowercaseString] replace:RX(@"[ ']")
                                                                          with:@"-"] replace:RX(@"[:.!]")
                                                                                        with:@""];

  cardLayer.contents = [[NSImage alloc] initWithContentsOfFile:[
    [[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:image]];

}

/*- (BOOL)wantsLayer
{
  return YES;
}*/

@end
