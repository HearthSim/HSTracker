/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "Mulligan.h"

@implementation Mulligan

+ (EMulligan)parse:(NSString *)rawValue
{
  if ([rawValue isEqualToString:@"INVALID"]) { return EMulligan_INVALID; }
  else if ([rawValue isEqualToString:@"INPUT"]) { return EMulligan_INPUT; }
  else if ([rawValue isEqualToString:@"DEALING"]) { return EMulligan_DEALING; }
  else if ([rawValue isEqualToString:@"WAITING"]) { return EMulligan_WAITING; }
  else if ([rawValue isEqualToString:@"DONE"]) { return EMulligan_DONE; }
  else { return (EMulligan) 0; }
}

@end
