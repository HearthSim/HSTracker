/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "LogLine.h"

@implementation LogLine

- (instancetype)initWithNamespace:(NSString *)namespace time:(NSTimeInterval)time line:(NSString *)line
{
  if (self = [super init]) {
    self.namespace = namespace;
    self.time = time;
    self.line = line;
  }
  return self;
}

- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.time=%lf", self.time];
  [description appendFormat:@", self.namespace=%@", self.namespace];
  [description appendFormat:@", self.line=%@", self.line];
  [description appendString:@">"];
  return description;
}


@end
