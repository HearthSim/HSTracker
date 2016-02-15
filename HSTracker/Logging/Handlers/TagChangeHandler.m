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

@implementation TagChangeHandler

- (void)tagChange:(NSString *)rawTag id:(NSNumber *)id rawValue:(NSString *)rawValue
{
  [self tagChange:rawTag id:id rawValue:rawValue recurse:NO];
}

- (void)tagChange:(NSString *)rawTag id:(NSNumber *)id rawValue:(NSString *)rawValue recurse:(BOOL)recurse
{
  Game *game = [Game instance];
  if (!game.entities[id]) {
    game.entities[id] = [[Entity alloc] initWithId:id];
  }

  EGameTag tag = [GameTag parse:rawTag];
  if (tag == 0) {
    if ([rawTag isMatch:RX(@"\\d+")]) {
      NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
      NSNumber *num = [formatter numberFromString:rawTag];
      if ([GameTag exists:num]) {
        tag = (EGameTag) [num integerValue];
      }
    }
  }
  NSInteger value = [self parseTag:tag rawValue:rawValue];
  NSNumber *prevZone = [game.entities[id] getTag:EGameTag_ZONE];
  [game.entities[id] setValue:@(value) forTag:tag];

  if (tag == EGameTag_CONTROLLER && game.waitController != nil && game.playerId == nil) {
    Entity *player1, *player2;
    for (Entity *ent in game.entities) {
      if ([ent hasTag:EGameTag_PLAYER_ID] && [[ent getTag:EGameTag_PLAYER_ID] isEqualToNumber:@(1)]) {
        player1 = ent;
      }
      else if ([ent hasTag:EGameTag_PLAYER_ID] && [[ent getTag:EGameTag_PLAYER_ID] isEqualToNumber:@(2)]) {
        player2 = ent;
      }
    }

    if (self.currentEntityHasCardId) {
      if (player1) {player1.isPlayer = (value == 1);}
      if (player2) {player2.isPlayer = (value != 1);}

      game.playerId = @(value);
      game.opponentId = @(value % 2 + 1);
    }
    else {
      if (player1) {player1.isPlayer = (value != 1);}
      if (player2) {player2.isPlayer = (value == 1);}

      game.playerId = @(value % 2 + 1);
      game.opponentId = @(value);
    }

    if (player1) {DDLogInfo(@"player1 is player : %@", player1.isPlayer ? @"YES" : @"NO");}
    if (player2) {DDLogInfo(@"player2 is player : %@", player2.isPlayer ? @"YES" : @"NO");}
  }

  NSNumber *controller = [game.entities[id] getTag:EGameTag_CONTROLLER];
  NSString *cardId = ((Entity *) game.entities[id]).cardId;

  switch (tag) {
    case EGameTag_ZONE: {
      if ((value == EZone_HAND || ((value == EZone_PLAY || value == EZone_DECK) && [game isMulliganDone])) && game.waitController == nil) {
        if (![game isMulliganDone]) {
          prevZone = @(EZone_DECK);
        }
        if ([controller isEqualToNumber:@0]) {
          [((Entity *) game.entities[id]) setValue:prevZone forTag:EGameTag_ZONE];
          game.waitController = [[TempEntity alloc] initWithTag:rawTag id:id value:rawValue];
          return;
        }
      }

      EZone prevZ = (EZone) ([prevZone integerValue]);
      switch (prevZ) {
        case EZone_DECK: {
          switch (value) {
            case EZone_HAND: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerDraw:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                if (cardId == nil || [cardId isEqualToString:@""]) {
                  ((Entity *) game.entities[id]).cardId = @"";
                }

                [game opponentDraw:[game turnNumber]];
              }
              break;
            }

            case EZone_REMOVEDFROMGAME:
            case EZone_SETASIDE: {
              if ([controller isEqualToNumber:game.playerId]) {
                if (game.joustReveals > 0) {
                  game.joustReveals -= 1;
                  return;
                }
                [game playerRemoveFromDeck:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                if (game.joustReveals > 0) {
                  game.joustReveals -= 1;
                  return;
                }
                [game opponentRemoveFromDeck:cardId turn:[game turnNumber]];
              }

              break;
            }

            case EZone_GRAVEYARD: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerDeckDiscard:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentDeckDiscard:cardId turn:[game turnNumber]];
              }
              break;
            }

            case EZone_PLAY: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerDeckToPlay:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentDeckToPlay:cardId turn:[game turnNumber]];
              }
              break;
            }

            case EZone_SECRET: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerSecretPlayed:cardId turn:[game turnNumber] fromDeck:YES];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentSecretPlayed:cardId from:@(-1) turn:[game turnNumber] fromDeck:YES id:id];
              }
              break;
            }

            default:
              break;
          }
          break;
        }

        case EZone_HAND: {
          switch (value) {
            case EZone_PLAY: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerPlay:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentPlay:cardId
                              from:[((Entity *) game.entities[id]) getTag:EGameTag_ZONE_POSITION]
                              turn:[game turnNumber]];
              }
              break;
            }

            case EZone_REMOVEDFROMGAME:
            case EZone_GRAVEYARD: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerHandDiscard:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentHandDiscard:cardId
                                     from:[((Entity *) game.entities[id]) getTag:EGameTag_ZONE_POSITION]
                                     turn:[game turnNumber]];
              }
              break;
            }

            case EZone_SECRET: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerSecretPlayed:cardId turn:[game turnNumber] fromDeck:NO];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentSecretPlayed:cardId
                                      from:[((Entity *) game.entities[id]) getTag:EGameTag_ZONE_POSITION]
                                      turn:[game turnNumber] fromDeck:NO id:id];
              }
              break;
            }

            case EZone_DECK: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game player_mulligan:cardId];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentMulligan:[((Entity *) game.entities[id]) getTag:EGameTag_ZONE_POSITION]];
              }
              break;
            }

            default:
              break;
          }
          break;
        }

        case EZone_PLAY: {
          switch (value) {
            case EZone_HAND: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerBackToHand:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentPlayToHand:cardId turn:[game turnNumber] id:id];
              }
              break;
            }

            case EZone_DECK: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerPlayToDeck:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentPlayToDeck:cardId turn:[game turnNumber]];
              }
              break;
            }

            case EZone_GRAVEYARD: {
              if ([((Entity *) game.entities[id]) hasTag:EGameTag_HEALTH]) {
                if ([controller isEqualToNumber:game.playerId]) {
                }
                else if ([controller isEqualToNumber:game.opponentId]) {
                }
              }
              break;
            }

            default:
              break;
          }

          break;
        }

        case EZone_SECRET: {
          switch (value) {
            case EZone_SECRET:
            case EZone_GRAVEYARD: {
              if ([controller isEqualToNumber:game.playerId]) {
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentSecretTrigger:cardId turn:[game turnNumber] id:id];
              }
              break;
            }
            default:
              break;
          }
          break;
        }

        case EZone_GRAVEYARD:
        case EZone_SETASIDE:
        case EZone_CREATED:
        case EZone_INVALID:
        case EZone_REMOVEDFROMGAME: {
          EZone val = (EZone) value;
          switch (val) {
            case EZone_PLAY: {
              break;
            }

            case EZone_DECK: {
              if ([controller isEqualToNumber:game.playerId]) {
                if (game.joustReveals > 0) {
                  return;
                }
                [game playerGetToDeck:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                if (game.joustReveals > 0) {
                  return;
                }
                [game opponentGetToDeck:cardId turn:[game turnNumber]];
              }
              break;
            }

            case EZone_HAND: {
              if ([controller isEqualToNumber:game.playerId]) {
                [game playerGet:cardId turn:[game turnNumber]];
              }
              else if ([controller isEqualToNumber:game.opponentId]) {
                [game opponentGet:[game turnNumber] id:id];
              }
              break;
            }

            default:
              break;
          }
          break;
        }

        default:
          break;
      }

      break;
    }

    case EGameTag_PLAYSTATE: {
      if (value == EPlayState_CONCEDED) {
        [game concede];
      }

      if (game.gameStarted) {
        if (((Entity *) game.entities[id]).isPlayer) {
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
      break;
    }

    case EGameTag_CURRENT_PLAYER: {
      if (value == 1) {
        // be sure to "reset" cards from tracking
        PlayerType player = ((Entity *) game.entities[id]).isPlayer ? Player : Opponent;
        [game turnStart:player turn:[game turnNumber]];

        if (player == Player) {
          self.playerUsedHeroPower = NO;
        }
        else {
          self.opponentUsedHeroPower = NO;
        }
      }
      break;
    }

    case EGameTag_NUM_ATTACKS_THIS_TURN: {
      if (value > 0) {
      }
      break;
    }

    case EGameTag_ZONE_POSITION: {
      break;
    }

    case EGameTag_CARD_TARGET: {
      if (value > 0) {
      }
      break;
    }

    case EGameTag_EQUIPPED_WEAPON: {
      if (value == 0) {
      }
      break;
    }

    case EGameTag_EXHAUSTED: {
      if (value > 0) {
      }
      break;
    }

    case EGameTag_CONTROLLER: {
      if ([game.entities[id] isInZone:EGameTag_SECRET]) {
        if ([game.playerId isEqualToNumber:@(value)]) {
          [game opponentSecretTrigger:cardId turn:[game turnNumber] id:id];
        }
      }
      break;
    }

    case EGameTag_FATIGUE: {
      if ([controller isEqualToNumber:game.playerId]) {
        [game playerFatigue:value];
      }
      else if ([controller isEqualToNumber:game.opponentId]) {
        [game opponentFatigue:value];
      }
      break;
    }

    default:
      break;
  }


  if (game.waitController != nil && !recurse) {
    [self tagChange:game.waitController.tag
                 id:game.waitController.id
           rawValue:game.waitController.value
            recurse:YES];
    game.waitController = nil;
  }
}

// parse an entity
- (NSDictionary *)parseEntity:(NSString *)entity
{
  NSNumber *id, *player;
  NSString *name, *zone, *zonePos, *cardId, *type;

  RxMatch *match;
  if ((match = [entity firstMatchWithDetails:RX(@"id=(\\d+)")]) != nil) {
    id = @([match.value intValue]);
  }

  if ((match = [entity firstMatchWithDetails:RX(@"name=(\\w+)")]) != nil) {
    name = match.value;
  }
  if ((match = [entity firstMatchWithDetails:RX(@"zone=(\\w+)")]) != nil) {
    zone = match.value;
  }
  if ((match = [entity firstMatchWithDetails:RX(@"zonePos=(\\d+)")]) != nil) {
    zonePos = match.value;
  }
  if ((match = [entity firstMatchWithDetails:RX(@"cardId=(\\w+)")]) != nil) {
    cardId = match.value;
  }
  if ((match = [entity firstMatchWithDetails:RX(@"player=(\\d+)")]) != nil) {
    player = @([match.value intValue]);
  }
  if ((match = [entity firstMatchWithDetails:RX(@"type=(\\w+)")]) != nil) {
    type = match.value;
  }

  return @{
    @"id" : id,
    @"player" : player,
    @"name" : name,
    @"zone" : zone,
    @"zonePos" : zonePos,
    @"cardId" : cardId,
    @"type" : type
  };
}

// check if the entity is a raw entity
- (BOOL)isEntity:(NSString *)entity
{
  NSDictionary *ent = [self parseEntity:entity];
  return ent[@"id"] != nil || ent[@"name"] != nil || ent[@"zone"] != nil || ent[@"zonePos"] != nil ||
    ent[@"cardId"] != nil || ent[@"player"] != nil || ent[@"type"] != nil;
}

- (NSInteger)parseTag:(EGameTag)tag rawValue:(NSString *)rawValue
{
  switch (tag) {
    case EGameTag_ZONE:
      return [Zone parse:rawValue];
    case EGameTag_MULLIGAN_STATE:
      return [Mulligan parse:rawValue];
    case EGameTag_PLAYSTATE:
      return [PlayState parse:rawValue];
    case EGameTag_CARDTYPE:
      return [CardType parse:rawValue];
    default: {
      if ([rawValue isKindOfClass:[NSString class]]) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *value = [formatter numberFromString:rawValue];
        if (value != nil) {
          return [value integerValue];
        }
      }
      return 0;
    }
  }
}

@end
