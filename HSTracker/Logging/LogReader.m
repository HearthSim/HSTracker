/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "LogReader.h"
#import "LogReaderManager.h"
#import "Hearthstone.h"
#import "LogLine.h"

@interface LogReader ()
{
  BOOL stopped;
  unsigned long long int offset;
  NSTimeInterval startingPoint;
}

@property(nonatomic, strong) NSString *name;
@property(nonatomic, weak) LogReaderManager *logReaderManager;
@property(nonatomic, strong) NSArray *startFilters;
@property(nonatomic, strong) NSArray *containsFilters;
@property(nonatomic, strong) NSString *path;

@end

@implementation LogReader

- (instancetype)initWithName:(NSString *)name
            logReaderManager:(LogReaderManager *)logReaderManager
{
  return [self initWithName:name
           logReaderManager:logReaderManager
               startFilters:nil
            containsFilters:nil];
}

- (instancetype)initWithName:(NSString *)name
            logReaderManager:(LogReaderManager *)logReaderManager
                startFilters:(NSArray *)startFilters
             containsFilters:(NSArray *)containsFilters
{
  self.name = name;
  self.logReaderManager = logReaderManager;
  self.startFilters = startFilters;
  self.containsFilters = containsFilters;

  self.path = [[[Hearthstone instance] logPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log", name]];

  return self;
}

- (NSTimeInterval)findEntryPoint:(NSString *)str
{
  if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
    return [NSDate distantPast].timeIntervalSinceReferenceDate;
  }

  NSError *error;
  NSString *fileContent = [NSMutableString stringWithContentsOfFile:self.path
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];

  // TODO check error
  NSArray *lines = [[[fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] reverseObjectEnumerator] allObjects];
  for (NSString *line in lines) {
    if ([line rangeOfString:str].location != NSNotFound) {
      NSDate *date = [self parseTime:line];

      return date.timeIntervalSinceReferenceDate;
    }
  }

  return [NSDate distantPast].timeIntervalSinceReferenceDate;
}

- (NSDate *)parseTime:(NSString *)line
{
  if ([line lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 18) {
    NSDictionary *fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path
                                                                                 error:nil];
    return fileAttribs[NSFileModificationDate];
  }

  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  NSString *day = [dateFormatter stringFromDate:[NSDate date]];

  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSS"];
  NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", day, [line substringWithRange:NSMakeRange(2, 16)]]];

  if ([date compare:[NSDate date]] == NSOrderedDescending) {
    date = [date dateByAddingTimeInterval:-(60 * 60 * 24 * 1)];
  }
  return date;
}

- (void)start:(NSTimeInterval)entryPoint
{
  DDLogInfo(@"Starting reader %@, (%@:%lf)", self.name, self.path, entryPoint);
  if ([[NSFileManager defaultManager] fileExistsAtPath:self.path] && ![[Hearthstone instance] isHearthstoneRunning]) {
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
  }

  stopped = NO;
  startingPoint = entryPoint;
  offset = [self findOffset];
  [self readFile];
}

- (void)readFile
{
  if (stopped) {
    return;
  }

  if ([[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    NSDictionary *fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path
                                                                                 error:nil];
    if (offset > [fileAttribs[NSFileSize] unsignedLongLongValue]) {
      offset = [self findOffset];
    }
    [fileHandle seekToFileOffset:offset];

    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *linesStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    offset += [linesStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [fileHandle closeFile];

    NSArray *lines = [[linesStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];

    for (NSString *line in lines) {
      NSDate *time = [self parseTime:line];
      if (time.timeIntervalSinceReferenceDate < startingPoint) {
        continue;
      }

      BOOL parse = NO;
      if (self.startFilters == nil || self.containsFilters == nil) {
        parse = YES;
      }
      else if (self.startFilters) {
        for (NSString *filter in self.startFilters) {
          NSString *reg = [NSString stringWithFormat:@"^%@", filter];
          if ([[line substringFromIndex:19] isMatch:RX(reg)]) {
            parse = YES;
            break;
          }
        }
      }

      if (self.containsFilters && !parse) {
        for (NSString *filter in self.containsFilters) {
          if ([[line substringFromIndex:19] isMatch:RX(filter)]) {
            parse = YES;
            break;
          }
        }
      }

      if (parse) {
        LogLine *logLine = [[LogLine alloc] initWithNamespace:self.name
                                                         time:time.timeIntervalSinceReferenceDate
                                                         line:line];
        [self.logReaderManager processNewLine:logLine];
      }
    }
  }
}

- (unsigned long long int)findOffset
{
  if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
    return 0;
  }

  offset = 0;
  NSError *error;
  NSString *fileContent = [NSMutableString stringWithContentsOfFile:self.path
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];

  // TODO check error
  NSArray *lines = [[[fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] reverseObjectEnumerator] allObjects];
  for (NSString *line in lines) {
    NSDate *time = [self parseTime:line];
    if (time.timeIntervalSinceReferenceDate < startingPoint) {
      offset += [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    }
  }

  return offset;
}

- (void)stop
{

  stopped = YES;
}

@end
