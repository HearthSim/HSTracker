/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

#import "Language.h"
#import "Settings.h"

@implementation Language
{
  LanguageChooser *languageChooser;
}

- (BOOL)isLanguageSet
{
  return [Settings hasKey:HearthstoneLanguage] && [Settings hasKey:HSTrackerLanguage];
}

- (void)presentLanguageChooserWithCompletion:(LanguageChooserCompletion)completion
{
  languageChooser = [[LanguageChooser alloc] init];
  languageChooser.completion = completion;
  [languageChooser showWindow:nil];
  [languageChooser.window orderFrontRegardless];
}

@end
