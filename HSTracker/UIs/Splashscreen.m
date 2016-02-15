/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "Splashscreen.h"

@interface Splashscreen ()
{
  IBOutlet NSTextField *information;
  IBOutlet NSProgressIndicator *progressBar;
}
@end

@implementation Splashscreen

- (instancetype)init
{
  return [self initWithWindowNibName:@"Splashscreen"];
}

- (void)display:(NSString *)str total:(NSUInteger)total
{
  information.stringValue = str;
  progressBar.maxValue = total;
  progressBar.doubleValue = 0;
}

- (void)increment
{
  [progressBar incrementBy:1];
}

@end
