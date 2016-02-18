/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 16/02/16.
 */
#import "ImageCache.h"
#import "Card.h"

typedef NS_ENUM(NSInteger, FromDestination)
{
    FromDestination_Bundle,
    FromDestination_Assets,
    FromDestination_Path,
};

@implementation ImageCache

+ (NSImage *)frameImageMask
{
  return [self imageNamed:@"frame_mask.png" from:FromDestination_Assets];
}

+ (NSImage *)smallCardImage:(Card *)card
{
  NSString *image = [[[card.englishName lowercaseString] replace:RX(@"[ ']")
                                                            with:@"-"] replace:RX(@"[:.!]")
                                                                          with:@""];
  return [self imageNamed:[NSString stringWithFormat:@"%@.png", image] from:FromDestination_Bundle];
}

+ (NSImage *)gemImage:(NSString *)rarity
{
  NSString *image;
  if ([rarity isEqualToString:@"free"]) {image = @"gem_rarity_free";}
  else if ([rarity isEqualToString:@"common"]) {image = @"gem_rarity_common";}
  else if ([rarity isEqualToString:@"rare"]) {image = @"gem_rarity_rare";}
  else if ([rarity isEqualToString:@"epic"]) {image = @"gem_rarity_epic";}
  else if ([rarity isEqualToString:@"legendary"]) {image = @"gem_rarity_legendary";}
  else {return nil;}

  return [self imageNamed:image from:FromDestination_Assets];
}

+ (NSImage *)frameDeckImage
{
  return [self imageNamed:@"frame_deck" from:FromDestination_Assets];
}

+ (NSImage *)frameImage:(NSString *)rarity
{
  NSString *image;
  if ([rarity isEqualToString:@"common"]) {image = @"frame_rarity_common";}
  else if ([rarity isEqualToString:@"rare"]) {image = @"frame_rarity_rare";}
  else if ([rarity isEqualToString:@"epic"]) {image = @"frame_rarity_epic";}
  else if ([rarity isEqualToString:@"legendary"]) {image = @"frame_rarity_legendary";}
  else {image = @"frame";}

  return [self imageNamed:image from:FromDestination_Assets];
}

+ (NSImage *)frameLegendary
{
  return [self imageNamed:@"frame_legendary" from:FromDestination_Assets];
}

+ (NSImage *)frameCount:(NSNumber *)number
{
  return [self imageNamed:[NSString stringWithFormat:@"frame_%@", number] from:FromDestination_Assets];
}

+ (NSImage *)frameCountbox
{
  return [self imageNamed:@"frame_countbox" from:FromDestination_Assets];
}

+ (NSImage *)frameCountboxDeck
{
  return [self imageNamed:@"frame_countbox_deck" from:FromDestination_Assets];
}

+ (NSImage *)imageNamed:(NSString *)path from:(FromDestination)from
{
  switch (from) {
    case FromDestination_Bundle: {
      NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
      DDLogVerbose(@"Opening image %@", fullPath);
      return [[NSImage alloc] initWithContentsOfFile:fullPath];
    }
    case FromDestination_Assets: {
      DDLogVerbose(@"Opening image %@", path);
      return [NSImage imageNamed:path];
    }
    case FromDestination_Path: {
      DDLogVerbose(@"Opening image %@", path);
      return [[NSImage alloc] initWithContentsOfFile:path];
    }
    default:
      return nil;
  }
}
@end
