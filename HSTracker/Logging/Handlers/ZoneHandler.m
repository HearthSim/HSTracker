/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "ZoneHandler.h"
#import "Game.h"

@implementation ZoneHandler

+ (void)handle:(NSString *)line
{
  NSRegularExpression *regex = RX(@"ProcessChanges.*TRANSITIONING card \\[name=(.*).*zone=PLAY.*cardId=(.*).*player=(\\d)\\] to (.*) \\(Hero\\)");
  if ([line isMatch:regex]) {

    NSArray *matches = [line matches:regex];
    NSString *cardId = [matches[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *to = matches[4];

    Game *game = [Game instance];
    if ([to isEqualToString:@"FRIENDLY PLAY"]) {
      [game setPlayerHero:cardId];
    }
    else {
      [game setOpponentHero:cardId];
    }
  }
}

@end
