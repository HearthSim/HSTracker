/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "Database.h"
#import "Settings.h"
#import "Card.h"
#import "CardMechanic.h"

#define DATABASE_VERSION 1

@implementation Database

- (void)loadDatabaseIfNeeded:(Splashscreen *)splashscreen
{
  NSNumber *dbVersion = [Settings instance].databaseVersion;
  if (dbVersion != nil && [dbVersion compare:@(DATABASE_VERSION)] == NSOrderedSame) {
    DDLogVerbose(@"Database already on version %@", @(DATABASE_VERSION));
    return;
  }

  // start by truncating everything
  [Card MR_truncateAll];
  [CardMechanic MR_truncateAll];

  NSArray *langs;
  if ([[Settings instance].hearthstoneLanguage isEqualToString:@"enUS"]) {
    langs = @[@"enUS"];
  }
  else {
    langs = @[@"enUS", [Settings instance].hearthstoneLanguage];
  }

  NSArray *validCardSet = @[@"CORE", @"EXPERT1", @"NAXX", @"GVG", @"BRM", @"TGT", @"LOE", @"PROMO", @"REWARD"];
  for (NSString *lang in langs) {
    NSString *jsonFile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"cardsDB.%@.json", lang]];
    DDLogVerbose(@"json file : %@", jsonFile);
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonFile];
    NSError *error;
    NSArray *cards = [NSJSONSerialization JSONObjectWithData:jsonData
                                                     options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments
                                                       error:&error];
    if (error) {
      DDLogError(@"JSON Error : %@", [error localizedDescription]);
      // TODO... do something here
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [splashscreen display:[NSString stringWithFormat:NSLocalizedString(@"Loading %@ cards", nil), lang]
                        total:[cards count]];
    });
    for (NSDictionary *jsonCard in cards) {
      dispatch_async(dispatch_get_main_queue(), ^{
          [splashscreen increment];
      });

      if (![validCardSet containsObject:jsonCard[@"set"]]) {
        continue;
      }
      [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *_Nonnull localContext) {
          Card *card = [Card MR_createEntityInContext:localContext];
          card.cardId = jsonCard[@"id"];
          card.lang = lang;

          // "fake" the coin... in the game files, Coin cost is empty
          // so we set it to 0
          if ([card.cardId isEqualTo:@"GAME_005"]) {
            card.cost = @0;
          }
          else {
            card.cost = jsonCard[@"cost"];
          }

          NSString *cardRarity = jsonCard[@"rarity"];
          if (cardRarity) {
            cardRarity = [cardRarity lowercaseString];
          }
          card.rarity = cardRarity;

          NSString *cardType = jsonCard[@"type"];
          if (cardType) {
            cardType = [cardType lowercaseString];
          }
          card.type = cardType;

          NSString *cardPlayerClass = jsonCard[@"playerClass"];
          if (cardPlayerClass) {
            cardPlayerClass = [cardPlayerClass lowercaseString];
          }
          card.playerClass = cardPlayerClass;

          NSString *cardFaction = jsonCard[@"faction"];
          if (cardFaction) {
            cardFaction = [cardFaction lowercaseString];
          }
          card.faction = cardFaction;

          NSString *cardSet = jsonCard[@"set"];
          if (cardSet) {
            cardSet = [cardSet lowercaseString];
          }
          card.set = cardSet;

          card.health = jsonCard[@"health"];
          card.flavor = jsonCard[@"flavor"];
          card.collectible = @(jsonCard[@"collectible"] != nil);
          card.name = jsonCard[@"name"];
          card.text = jsonCard[@"text"];

          if (jsonCard[@"mechanics"]) {
            for (NSString *mechanic in jsonCard[@"mechanics"]) {
              NSString *_mechanic = [mechanic lowercaseString];
              CardMechanic *cardMechanic = [CardMechanic MR_findFirstByAttribute:@"name" withValue:_mechanic];
              if (cardMechanic == nil) {
                cardMechanic = [CardMechanic MR_createEntityInContext:localContext];
                cardMechanic.name = _mechanic;
              }
              [card addMechanicsObject:cardMechanic];
            }
          }
      }];
    }
  }

  [Settings instance].databaseVersion = @(DATABASE_VERSION);
}

@end
