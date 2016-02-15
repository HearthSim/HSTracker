/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import <Cocoa/Cocoa.h>

@interface Splashscreen : NSWindowController

- (void)display:(NSString *)str total:(NSUInteger)total;

- (void)increment;

@end
