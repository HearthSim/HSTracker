/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "TagChangeHandler.h"
#import "Zone.h"
#import "Mulligan.h"
#import "PlayState.h"
#import "CardType.h"
#import "Game.h"
#import "Entity.h"
#import "NSString+HSTracker.h"
#import "TagClass.h"
#import "Player.h"

@implementation TagChangeHandler

- (void)tagChange:(NSString *)rawTag id:(NSInteger)id rawValue:(NSString *)rawValue
{
  [self tagChange:rawTag id:id rawValue:rawValue recurse:NO];
}

- (void)tagChange:(NSString *)rawTag id:(NSInteger)id rawValue:(NSString *)rawValue recurse:(BOOL)recurse
{
  Game *game = [Game instance];
  if (!game.entities[@(id)]) {
    game.entities[@(id)] = [[Entity alloc] initWithId:id];
  }

  EGameTag tag;
  if (![GameTag tryParse:rawTag out:&tag]) {
    DDLogInfo(@"tag not found -> rawTag %@", rawTag);
    NSInteger num;
    if ([rawTag tryParse:&num] && [GameTag exists:num]) {
      DDLogInfo(@"tag not found -> rawTag %ld", num);
      tag = (EGameTag) num;
    }
  }
  NSInteger value = [self parseTag:tag rawValue:rawValue];
  NSInteger prevValue = [game.entities[@(id)] getTag:tag];
  [game.entities[@(id)] setValue:value forTag:tag];

  if (tag == EGameTag_CONTROLLER && game.waitController != nil && game.player.id == NSNotFound) {
    Entity *player1, *player2;
    for (Entity *ent in [game.entities allValues]) {
      if ([ent getTag:EGameTag_PLAYER_ID] == 1) {
        player1 = ent;
      }
      else if ([ent getTag:EGameTag_PLAYER_ID] == 2) {
        player2 = ent;
      }
    }
    if (self.currentEntityHasCardId) {
      if (player1) {player1.isPlayer = (value == 1);}
      if (player2) {player2.isPlayer = (value != 1);}

      game.player.id = value;
      game.opponent.id = value % 2 + 1;
    }
    else {
      if (player1) {player1.isPlayer = (value != 1);}
      if (player2) {player2.isPlayer = (value == 1);}

      game.player.id = value % 2 + 1;
      game.opponent.id = value;
    }

    if (player1) {DDLogInfo(@"player1 is player : %@", player1.isPlayer ? @"YES" : @"NO");}
    if (player2) {DDLogInfo(@"player2 is player : %@", player2.isPlayer ? @"YES" : @"NO");}
  }

  NSInteger controller = [game.entities[@(id)] getTag:EGameTag_CONTROLLER];
  NSString *cardId = ((Entity *) game.entities[@(id)]).cardId;
  //DDLogVerbose(@"Entity %ld, Controller is %ld, player is %ld, opponent is %ld, card %@", id, controller, game.player.id, game.opponent.id, cardId);

  if (tag == EGameTag_ZONE) {
    if ((value == EZone_HAND || ((value == EZone_PLAY || value == EZone_DECK) && [game isMulliganDone]))
      && game.waitController == nil) {
      if (![game isMulliganDone]) {
        prevValue = EZone_DECK;
      }
      if (controller == 0) {
        [((Entity *) game.entities[@(id)]) setValue:prevValue forTag:EGameTag_ZONE];
        game.waitController = [[TempEntity alloc] initWithTag:rawTag id:id value:rawValue];
        return;
      }
    }

    switch (prevValue) {
      case EZone_DECK: {
        switch (value) {
          case EZone_HAND: {
            if (controller == game.player.id) {
              [game playerDraw:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              if (((Entity *) game.entities[@(id)]).cardId != nil || ![((Entity *) game.entities[@(id)]).cardId isEmpty]) {
                ((Entity *) game.entities[@(id)]).cardId = nil;
              }

              [game opponentDraw:game.entities[@(id)] turn:[game turnNumber]];
            }
            break;
          }

          case EZone_REMOVEDFROMGAME:
          case EZone_SETASIDE: {
            if (controller == game.player.id) {
              if (game.joustReveals > 0) {
                game.joustReveals -= 1;
                break;
              }
              [game playerRemoveFromDeck:game.entities[@(id)] turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              if (game.joustReveals > 0) {
                game.joustReveals -= 1;
                break;
              }
              [game opponentRemoveFromDeck:game.entities[@(id)] turn:[game turnNumber]];
            }

            break;
          }

          case EZone_GRAVEYARD: {
            if (controller == game.player.id) {
              [game playerDeckDiscard:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentDeckDiscard:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            break;
          }

          case EZone_PLAY: {
            if (controller == game.player.id) {
              [game playerDeckToPlay:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentDeckToPlay:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            break;
          }

          case EZone_SECRET: {
            if (controller == game.player.id) {
              [game playerSecretPlayed:game.entities[@(id)] card:cardId turn:[game turnNumber] fromDeck:YES];
            }
            else if (controller == game.opponent.id) {
              [game opponentSecretPlayed:game.entities[@(id)] card:cardId from:-1 turn:[game turnNumber] fromDeck:YES id:id];
            }
            break;
          }

          default:
            //DDLogVerbose(@"WARNING - unhandled zone change (id=%ld): %ld -> %ld", id, prevValue, value);
            break;
        }
        break;
      }

      case EZone_HAND: {
        switch (value) {
          case EZone_PLAY: {
            if (controller == game.player.id) {
              [game playerPlay:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentPlay:game.entities[@(id)]
                            card:cardId
                            from:[((Entity *) game.entities[@(id)]) getTag:EGameTag_ZONE_POSITION]
                            turn:[game turnNumber]];
            }
            break;
          }

          case EZone_REMOVEDFROMGAME:
          case EZone_SETASIDE:
          case EZone_GRAVEYARD: {
            if (controller == game.player.id) {
              [game playerHandDiscard:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentHandDiscard:game.entities[@(id)]
                                   card:cardId
                                   from:[((Entity *) game.entities[@(id)]) getTag:EGameTag_ZONE_POSITION]
                                   turn:[game turnNumber]];
            }
            break;
          }

          case EZone_SECRET: {
            if (controller == game.player.id) {
              [game playerSecretPlayed:game.entities[@(id)]
                                  card:cardId
                                  turn:[game turnNumber]
                              fromDeck:NO];
            }
            else if (controller == game.opponent.id) {
              [game opponentSecretPlayed:game.entities[@(id)]
                                    card:cardId
                                    from:[((Entity *) game.entities[@(id)]) getTag:EGameTag_ZONE_POSITION]
                                    turn:[game turnNumber]
                                fromDeck:NO
                                      id:id];
            }
            break;
          }

          case EZone_DECK: {
            if (controller == game.player.id) {
              [game playerMulligan:game.entities[@(id)] card:cardId];
            }
            else if (controller == game.opponent.id) {
              [game opponentMulligan:game.entities[@(id)] from:[((Entity *) game.entities[@(id)]) getTag:EGameTag_ZONE_POSITION]];
            }
            break;
          }

          default:
            //DDLogVerbose(@"WARNING - unhandled zone change (id=%ld): %ld -> %ld", id, prevValue, value);
            break;
        }
        break;
      }

      case EZone_PLAY: {
        switch (value) {
          case EZone_HAND: {
            if (controller == game.player.id) {
              [game playerBackToHand:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentPlayToHand:game.entities[@(id)] card:cardId turn:[game turnNumber] id:id];
            }
            break;
          }

          case EZone_DECK: {
            if (controller == game.player.id) {
              [game playerPlayToDeck:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentPlayToDeck:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            break;
          }

          case EZone_REMOVEDFROMGAME:
          case EZone_SETASIDE:
          case EZone_GRAVEYARD: {
            if (controller == game.player.id) {
              [game playerPlayToGraveyard:game.entities[@(id)] card:cardId turn:[game turnNumber]];
              if ([((Entity *) game.entities[@(id)]) hasTag:EGameTag_HEALTH]) {}
            }
            else if (controller == game.opponent.id) {
              // TODO gameState.GameHandler.HandleOpponentPlayToGraveyard(game.Entities[id], cardId, gameState.GetTurnNumber(), gameState.PlayersTurn());
              [game opponentPlayToGraveyard:game.entities[@(id)] card:cardId turn:[game turnNumber]];
              if ([((Entity *) game.entities[@(id)]) hasTag:EGameTag_HEALTH]) {}
            }
            break;
          }

          default:
            //DDLogVerbose(@"WARNING - unhandled zone change (id=%ld): %ld -> %ld", id, prevValue, value);
            break;
        }

        break;
      }

      case EZone_SECRET: {
        switch (value) {
          case EZone_SECRET:
          case EZone_GRAVEYARD: {
            if (controller == game.player.id) {
            }
            else if (controller == game.opponent.id) {
              [game opponentSecretTrigger:game.entities[@(id)] card:cardId turn:[game turnNumber] id:id];
            }
            break;
          }
          default:
            //DDLogVerbose(@"WARNING - unhandled zone change (id=%ld): %ld -> %ld", id, prevValue, value);
            break;
        }
        break;
      }

      case EZone_GRAVEYARD:
      case EZone_SETASIDE:
      case EZone_CREATED:
      case EZone_INVALID:
      case EZone_REMOVEDFROMGAME: {
        switch (value) {
          case EZone_PLAY: {
            if (controller == game.player.id) {
              [game playerCreateInPlay:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentCreateInPlay:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            break;
          }

          case EZone_DECK: {
            if (controller == game.player.id) {
              if (game.joustReveals > 0) {
                break;
              }
              [game playerGetToDeck:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              if (game.joustReveals > 0) {
                break;
              }
              [game opponentGetToDeck:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            break;
          }

          case EZone_HAND: {
            if (controller == game.player.id) {
              [game playerGet:game.entities[@(id)] card:cardId turn:[game turnNumber]];
            }
            else if (controller == game.opponent.id) {
              [game opponentGet:game.entities[@(id)] turn:[game turnNumber] id:id];
            }
            break;
          }

          default:
            //DDLogVerbose(@"WARNING - unhandled zone change (id=%ld): %ld -> %ld", id, prevValue, value);
            break;
        }
        break;
      }

      default:
        //DDLogVerbose(@"WARNING - unhandled zone change (id=%ld): %ld -> %ld", id, prevValue, value);
        break;
    }
  }

  else if (tag == EGameTag_PLAYSTATE) {
    if (value == EPlayState_CONCEDED) {
      [game concede];
    }

    if (game.gameStarted) {
      if (((Entity *) game.entities[@(id)]).isPlayer) {
        if (value == EPlayState_WON) {
          game.gameStarted = NO;
          [game win];
          [game gameEnd];
        }
        else if (value == EPlayState_LOST) {
          game.gameStarted = NO;
          [game loss];
          [game gameEnd];
        }
        else if (value == EPlayState_TIED) {
          game.gameStarted = NO;
          [game tied];
          [game gameEnd];
        }
      }
    }
  }

  else if (tag == EGameTag_CARDTYPE && value == ECardType_HERO) {
    [self setHeroAsync:id];
  }
  else if (tag == EGameTag_CURRENT_PLAYER && value == 1) {
    if (value == 1) {
      // be sure to "reset" cards from tracking
      PlayerType player = ((Entity *) game.entities[@(id)]).isPlayer ? PlayerType_Player : PlayerType_Opponent;
      [game turnStart:player turn:[game turnNumber]];

      if (player == PlayerType_Player) {
        self.playerUsedHeroPower = NO;
      }
      else {
        self.opponentUsedHeroPower = NO;
      }
    }
  }

  else if (tag == EGameTag_LAST_CARD_PLAYED) {
    //gameState.LastCardPlayed = value;
  }

  else if (tag == EGameTag_DEFENDING) {}
  else if (tag == EGameTag_ATTACKING) {}
  else if (tag == EGameTag_PROPOSED_DEFENDER) {}
  else if (tag == EGameTag_PROPOSED_ATTACKER) {}
  else if (tag == EGameTag_NUM_ATTACKS_THIS_TURN && value > 0) {}
  else if (tag == EGameTag_PREDAMAGE && value > 0) {}
  else if (tag == EGameTag_NUM_TURNS_IN_PLAY && value > 0) {}
  else if (tag == EGameTag_NUM_ATTACKS_THIS_TURN && value > 0) {}
  else if (tag == EGameTag_ZONE_POSITION) {}
  else if (tag == EGameTag_CARD_TARGET && value > 0) {}
  else if (tag == EGameTag_EQUIPPED_WEAPON && value == 0) {}
  else if (tag == EGameTag_EXHAUSTED && value > 0) {}

  else if (tag == EGameTag_CONTROLLER && prevValue > 0) {
    if (value == game.player.id) {
      if ([game.entities[@(id)] isInZone:EZone_SECRET]) {
        [game opponentStolen:game.entities[@(id)] card:cardId turn:[game turnNumber]];
      }
      else if ([game.entities[@(id)] isInZone:EZone_PLAY]) {
        [game opponentStolen:game.entities[@(id)] card:cardId turn:[game turnNumber]];
      }
    }
    else if (value == game.opponent.id) {
      if ([game.entities[@(id)] isInZone:EZone_SECRET]) {
        [game opponentStolen:game.entities[@(id)] card:cardId turn:[game turnNumber]];
      }
      else if ([game.entities[@(id)] isInZone:EZone_PLAY]) {
        [game playerStolen:game.entities[@(id)] card:cardId turn:[game turnNumber]];
      }
    }
  }

  else if (tag == EGameTag_FATIGUE) {
    if (controller == game.player.id) {
      [game playerFatigue:value];
    }
    else if (controller == game.opponent.id) {
      [game opponentFatigue:value];
    }
  }

  if (game.waitController != nil && !recurse) {
    [self tagChange:game.waitController.tag
                 id:game.waitController.id
           rawValue:game.waitController.value
            recurse:YES];
    game.waitController = nil;
  }
}

- (void)setHeroAsync:(NSInteger)id
{
  DDLogInfo(@"Found hero with id %ld", id);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      Game *game = [Game instance];
      if ([game playerEntity] == nil) {
        DDLogInfo(@"Waiting for playerEntity");
        while ([game playerEntity] == nil) {
          [NSThread sleepForTimeInterval:0.1];
        }
        DDLogInfo(@"Found playerEntity");
      }
      if (id == [[game playerEntity] getTag:EGameTag_HERO_ENTITY]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [game setPlayerHero:((Entity *) game.entities[@(id)]).cardId];
        });
        return;
      }

      if (game.opponentEntity == nil) {
        DDLogInfo(@"Waiting for opponentEntity");
        while ([game opponentEntity] == nil) {
          [NSThread sleepForTimeInterval:0.1];
        }
        DDLogInfo(@"Found opponentEntity");
      }
      if (id == [[game opponentEntity] getTag:EGameTag_HERO_ENTITY]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [game setOpponentHero:((Entity *) game.entities[@(id)]).cardId];
        });
        return;
      }
  });
}

// parse an entity
- (NSDictionary *)parseEntity:(NSString *)entity
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  RxMatch *match;
  for (NSString *key in @[@"id", @"zonePos", @"player"]) {
    NSString *regex = [NSString stringWithFormat:@"%@=(\\d+)", key];

    if ([entity isMatch:RX(regex)]) {
      match = [entity firstMatchWithDetails:RX(regex)];
      //DDLogVerbose(@"parse entity: %@ -> %@", regex, match.groups[1]);
      dict[key] = @([((RxMatchGroup *) match.groups[1]).value integerValue]);
    }
    else {
      dict[key] = [NSNull null];
    }
  }

  for (NSString *key in @[@"name", @"zone", @"cardId", @"type"]) {
    NSString *regex = [NSString stringWithFormat:@"%@=(\\d+)", key];

    if ([entity isMatch:RX(regex)]) {
      match = [entity firstMatchWithDetails:RX(regex)];
      //DDLogVerbose(@"parse entity: %@ -> %@", regex, match.groups[1]);
      dict[key] = ((RxMatchGroup *) match.groups[1]).value;
    }
    else {
      dict[key] = [NSNull null];
    }
  }

  return dict;
}

// check if the entity is a raw entity
- (BOOL)isEntity:(NSString *)entity
{
  NSDictionary *ent = [self parseEntity:entity];
  return ent[@"id"] != [NSNull null] || ent[@"name"] != [NSNull null] || ent[@"zone"] != [NSNull null]
    || ent[@"zonePos"] != [NSNull null] || ent[@"cardId"] != [NSNull null] || ent[@"player"] != [NSNull null]
    || ent[@"type"] != [NSNull null];
}

- (NSInteger)parseTag:(EGameTag)tag rawValue:(NSString *)rawValue
{
  switch (tag) {
    case EGameTag_ZONE: {
      EZone zone;
      [Zone tryParse:rawValue out:&zone];
      return zone;
    }
    case EGameTag_MULLIGAN_STATE: {
      EMulligan mulligan;
      [Mulligan tryParse:rawValue out:&mulligan];
      return mulligan;
    }
    case EGameTag_PLAYSTATE: {
      EPlayState playState;
      [PlayState tryParse:rawValue out:&playState];
      return playState;
    }
    case EGameTag_CARDTYPE: {
      ECardType cardType;
      [CardType tryParse:rawValue out:&cardType];
      return cardType;
    }
    case EGameTag_CLASS: {
      ETagClass tagClass;
      [TagClass tryParse:rawValue out:&tagClass];
      return tagClass;
    }
    default: {
      NSInteger value;
      [rawValue tryParse:&value];
      return value;
    }
  }
}

@end
