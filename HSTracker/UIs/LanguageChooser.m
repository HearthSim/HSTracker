/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "LanguageChooser.h"
#import "Settings.h"

@interface LanguageChooser () <NSComboBoxDataSource>
{
  IBOutlet NSWindow *window;
  IBOutlet NSComboBox *hstrackerLanguage;
  IBOutlet NSComboBox *hearthstoneLanguage;

  NSDictionary *hstrackerLanguages;
  NSDictionary *hearthstoneLanguages;
}
@end

@implementation LanguageChooser

- (instancetype)init
{
  return [self initWithWindowNibName:@"LanguageChooser"];
}

- (void)windowDidLoad
{
  [super windowDidLoad];

  NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
  for (NSString *loc in @[@"de", @"en", @"fr", @"it", @"pt-br", @"zh-cn", @"es"]) {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:loc];
    NSString *display = [locale displayNameForKey:NSLocaleIdentifier value:loc];
    tmp[loc] = display;
  }
  hstrackerLanguages = [NSDictionary dictionaryWithDictionary:tmp];

  tmp = [[NSMutableDictionary alloc] init];
  NSDictionary *locales = @{
    @"deDE" : @"de_DE",
    @"enUS" : @"en_US",
    @"esES" : @"es_ES",
    @"esMX" : @"es_MX",
    @"frFR" : @"fr_FR",
    @"itIT" : @"it_IT",
    @"koKR" : @"ko_KR",
    @"plPL" : @"pl_PL",
    @"ptBR" : @"pt_BR",
    @"ruRU" : @"ru_RU",
    @"zhCN" : @"zh_CN",
    @"zhTW" : @"zh_TW",
    @"jaJP" : @"ja_JP"
  };
  for (NSString *loc in [locales allKeys]) {
    NSString *appleLanguage = locales[loc];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:appleLanguage];
    NSString *display = [locale displayNameForKey:NSLocaleIdentifier value:appleLanguage];
    tmp[loc] = display;
  }
  hearthstoneLanguages = [NSDictionary dictionaryWithDictionary:tmp];

  hstrackerLanguage.usesDataSource = YES;
  hstrackerLanguage.dataSource = self;

  hearthstoneLanguage.usesDataSource = YES;
  hearthstoneLanguage.dataSource = self;
}

- (IBAction)save:(id)sender
{
  NSString *hstracker = [hstrackerLanguages allKeys][hstrackerLanguage.indexOfSelectedItem];
  NSString *hearthstone = [hearthstoneLanguages allKeys][hearthstoneLanguage.indexOfSelectedItem];

  DDLogDebug(@"Setting HSTracker locale to %@ and Hearthstone locale to %@", hstracker, hearthstone);
  [Settings setObject:hearthstone forKey:HearthstoneLanguage];
  [Settings setObject:hstracker forKey:HSTrackerLanguage];

  dispatch_async(dispatch_get_main_queue(), ^{
      self.completion();
  });

  [self.window close];
}

#pragma mark - NSComboBoxDataSource methods

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
  if ([aComboBox isEqualTo:hstrackerLanguage]) {
    return [[hstrackerLanguages allValues] count];
  }
  else if ([aComboBox isEqualTo:hearthstoneLanguage]) {
    return [[hearthstoneLanguages allValues] count];
  }

  return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
  if ([aComboBox isEqualTo:hstrackerLanguage]) {
    return [hstrackerLanguages allValues][index];
  }
  else if ([aComboBox isEqualTo:hearthstoneLanguage]) {
    return [hearthstoneLanguages allValues][index];
  }

  return NULL;
}

@end
