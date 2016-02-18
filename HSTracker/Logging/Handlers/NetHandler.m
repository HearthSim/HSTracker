/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
#import "NetHandler.h"
#import "Game.h"

@implementation NetHandler

+ (void)handle:(NSString *)line
{
  NSString *regex = @"ConnectAPI\\.GotoGameServer -- address=(.+), game=(.+), client=(.+), spectateKey=(.+)";
  if ([line isMatch:RX(regex)]) {
    //RxMatch *match = [line firstMatchWithDetails:RX(regex)];

    // game start
    [[Game instance] gameStart];
  }
}

@end
