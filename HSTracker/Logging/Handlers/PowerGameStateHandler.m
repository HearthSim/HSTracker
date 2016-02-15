/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "PowerGameStateHandler.h"
#import "TagChangeHandler.h"
#import "GameMode.h"
#import "Game.h"
#import "Entity.h"
#import "Card.h"

static NSString *const GameEntity = @"GameEntity EntityID=(\\d+)";
static NSString *const PlayerEntity = @"Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)";
static NSString *const TagPlayerChange = @"TAG_CHANGE Entity=([\\w\\s]+\\w) tag=PLAYER_ID value=(\\d)";
static NSString *const TagChange = @"TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)";
static NSString *const FullEntity = @"FULL_ENTITY - Creating ID=(\\d+) CardID=(\\w*)";
static NSString *const ShowEntity = @"SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)";
static NSString *const Tag = @"tag=(\\w+) value=(\\w+)";
static NSString *const ActionStart = @".*ACTION_START.*id=(\\w*).*cardId=(\\w*).*BlockType=POWER.*Target=(.+)";

@implementation PowerGameStateHandler

+ (void)handle:(NSString *)line
{
  static TagChangeHandler *tagChangeHandler;
  tagChangeHandler = [TagChangeHandler new];
  static NSNumber *currentEntityId = nil;
  static Entity *currentEntity;
  Entity *entity = nil;
  RxMatch *match;

  Game *game = [Game instance];

  // game start
  if ([line isMatch:RX(@"CREATE_GAME")]) {
    [game gameStart];
  }

    // current game
  else if ([line isMatch:RX(GameEntity)]) {
    [game gameStart];

    match = [line firstMatchWithDetails:RX(GameEntity)];
    NSNumber *id = @([match.value intValue]);

    if (!game.entities[id]) {
      game.entities[id] = [[Entity alloc] initWithId:id];
    }
    currentEntityId = id;
  }

    // players
  else if ([line isMatch:RX(PlayerEntity)]) {
    match = [line firstMatchWithDetails:RX(PlayerEntity)];
    NSNumber *id = @([match.value intValue]);

    if (!game.entities[id]) {
      game.entities[id] = [[Entity alloc] initWithId:id];
    }
    currentEntityId = id;
  }

  else if ([line isMatch:RX(TagPlayerChange)]) {
    NSArray *matches = [line matches:RX(TagPlayerChange)];
    NSString *name = ((RxMatch *) matches[1]).value;
    NSNumber *player = @([((RxMatch *) matches[2]).value intValue]);

    for (Entity *ent in [game.entities allValues]) {
      if ([ent hasTag:EGameTag_PLAYER_ID] && [[ent getTag:EGameTag_PLAYER_ID] isEqualToNumber:player]) {
        entity = ent;
        break;
      }
    }

    if (entity == nil) {
      return;
    }

    if ([entity isPlayer]) {
      [game setPlayerName:name];
    }
    else {
      [game setOpponentName:name];
    }
  }

  else if ([line isMatch:RX(TagChange)]) {
    NSArray *matches = [line matches:RX(TagChange)];
    NSString *rawEntity = [((RxMatch *) matches[1]).value stringByReplacingOccurrencesOfString:@"UNKNOWN ENTITY "
                                                                                    withString:@""];
    NSString *tag = ((RxMatch *) matches[1]).value;
    NSString *value = ((RxMatch *) matches[1]).value;

    if ([rawEntity isMatch:RX(@"^\\[")] && [tagChangeHandler isEntity:rawEntity]) {
      NSDictionary *dict = [tagChangeHandler parseEntity:rawEntity];
      NSNumber *id = dict[@"id"];
      [tagChangeHandler tagChange:tag id:id rawValue:value];
    }
    else if ([rawEntity isMatch:RX(@"\\d+")]) {
      NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
      [tagChangeHandler tagChange:tag id:[formatter numberFromString:rawEntity] rawValue:value];
    }
    else {
      Entity *sEntity;
      for (Entity *ent in [game.entities allValues]) {
        if ([ent.name isEqualToString:rawEntity]) {
          sEntity = ent;
          break;
        }
      }

      if (sEntity == nil) {
        Entity *tmpEntity;
        for (Entity *ent in [game.entities allValues]) {
          if ([ent.name isEqualToString:@"UNKNOWN HUMAN PLAYER"]) {
            tmpEntity = ent;
            tmpEntity.name = rawEntity;
          }
        }

        if (tmpEntity == nil) {
          for (Entity *ent in [game.entities allValues]) {
            if ([ent.name isEqualToString:rawEntity]) {
              tmpEntity = ent;
              break;
            }
          }
        }

        if (tmpEntity == nil) {
          tmpEntity = [[Entity alloc] initWithId:@(game.tmpEntities.count + 1)];
          tmpEntity.name = rawEntity;
          [game.tmpEntities addObject:tmpEntity];
        }

        EGameTag _tag = [GameTag parse:tag];
        NSInteger tagValue = [tagChangeHandler parseTag:_tag rawValue:value];
        [tmpEntity setValue:@(tagValue) forTag:_tag];
        if ([tmpEntity hasTag:EGameTag_ENTITY_ID]) {
          NSNumber *id = [tmpEntity getTag:EGameTag_ENTITY_ID];

          if (game.entities[id]) {
            ((Entity *) game.entities[id]).name = tmpEntity.name;
            for (NSNumber *key in [tmpEntity.tags allKeys]) {
              [((Entity *) game.entities[id]) setValue:tmpEntity.tags[key] forTag:[key integerValue]];
            }
            [game.tmpEntities removeObject:tmpEntity];
          }
        }
      }
      else {
        [tagChangeHandler tagChange:tag
                                 id:sEntity.id
                           rawValue:value];
      }
    }
  }

  else if ([line isMatch:RX(FullEntity)]) {
    NSArray *matches = [line matches:RX(FullEntity)];
    NSNumber *id = @([((RxMatch *) matches[0]).value intValue]);
    NSString *cardId = ((RxMatch *) matches[0]).value;

    if (!game.entities[id]) {
      entity = [[Entity alloc] initWithId:id];
      entity.cardId = cardId;
      game.entities[id] = entity;
    }
    currentEntityId = id;
    tagChangeHandler.currentEntityHasCardId = !(cardId == nil || [cardId isEqualToString:@""]);
  }

  else if ([line isMatch:RX(ShowEntity)]) {
    NSArray *matches = [line matches:RX(FullEntity)];
    NSString *tmpEntity = ((RxMatch *) matches[1]).value;
    NSString *cardId = ((RxMatch *) matches[2]).value;

    NSNumber *entityId;
    if ([tmpEntity isMatch:RX(@"^\\[")] && [tagChangeHandler isEntity:tmpEntity]) {
      NSDictionary *dict = [tagChangeHandler parseEntity:tmpEntity];
      entityId = dict[@"id"];
    }
    else {
      NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
      entityId = [formatter numberFromString:tmpEntity];
    }

    if (entityId != nil && ![entityId isEqualToNumber:@(-1)]) {
      if (!game.entities[entityId]) {
        entity = [[Entity alloc] initWithId:entityId];
        game.entities[entityId] = entity;
      }
      ((Entity *) game.entities[entityId]).cardId = cardId;
      currentEntity = entity;
      currentEntityId = entityId;
    }

    if (game.joustReveals > 0) {
      currentEntity = game.entities[entityId];
      if (currentEntity) {
        if ([currentEntity isControllerBy:game.opponentId]) {
          [game opponentJoust:cardId turn:[game turnNumber]];
        }
        else if ([currentEntity isControllerBy:game.playerId]) {
          [game playerJoust:cardId turn:[game turnNumber]];
        }
      }
    }
  }

  else if ([line isMatch:RX(Tag)] && ![line isMatch:RX(@"HIDE_ENTITY")]) {
    NSArray *matches = [line matches:RX(Tag)];
    NSString *tag = matches[1];
    NSString *value = matches[2];

    [tagChangeHandler tagChange:tag
                             id:currentEntityId
                       rawValue:value];
  }

  else if ([line isMatch:RX(@"Begin Spectating")] || [line isMatch:RX(@"Start Spectator")]) {
    game.gameMode = GameMode_Spectator;
  }

  else if ([line isMatch:RX(@"End Spectator")]) {
    game.gameMode = GameMode_Spectator;
    [game gameEnd];
  }

  else if ([line isMatch:RX(ActionStart)]) {
    NSArray *matches = [line matches:RX(FullEntity)];
    NSNumber *id = @([((RxMatch *) matches[1]).value intValue]);
    NSString *localId = ((RxMatch *) matches[2]).value;
    NSString *target = ((RxMatch *) matches[3]).value;

    Entity *player, *opponent;
    for (Entity *ent in game.entities) {
      if ([ent hasTag:EGameTag_PLAYER_ID] && [[ent getTag:EGameTag_PLAYER_ID] isEqualToNumber:game.playerId]) {
        player = ent;
      }
      else if ([ent hasTag:EGameTag_PLAYER_ID] && [[ent getTag:EGameTag_PLAYER_ID] isEqualToNumber:game.opponentId]) {
        opponent = ent;
      }
    }

    if ((localId == nil || [localId isEqualToString:@""]) && id != nil) {
      entity = game.entities[id];
      localId = entity.cardId;
    }

    if ([localId isEqualToString:@"BRM_007"]) { // Gang Up
      NSString *cardId;
      if ([target isMatch:RX(@"^\\[")] && [tagChangeHandler isEntity:target]) {
        if ([target isMatch:RX(@"cardId=(\\w+)")]) {
          cardId = [target firstMatch:RX(@"cardId=(\\w+)")];
        }
      }

      if (player != nil && [[player getTag:EGameTag_CURRENT_PLAYER] isEqualToNumber:@(1)]) {
        if (cardId) {
          for (NSUInteger i = 0; i < 3; i++) {
            [game playerGetToDeck:cardId turn:[game turnNumber]];
          }
        }
      }
      else {
        for (NSUInteger i = 0; i < 3; i++) {
          [game opponentGetToDeck:cardId turn:[game turnNumber]];
        }
      }
    }

    else if ([localId isEqualToString:@"GVG_056"]) { // Iron Juggernaut
      if (player != nil && [[player getTag:EGameTag_CURRENT_PLAYER] isEqualToNumber:@(1)]) {
        [game opponentGetToDeck:@"GVG_056t" turn:[game turnNumber]];
      }
      else {
        [game playerGetToDeck:@"GVG_056t" turn:[game turnNumber]];
      }
    }

    else if ((player && [[player getTag:EGameTag_CURRENT_PLAYER] isEqualToNumber:@(1)] && tagChangeHandler.playerUsedHeroPower) ||
      (opponent && [[opponent getTag:EGameTag_CURRENT_PLAYER] isEqualToNumber:@(1)] && !tagChangeHandler.opponentUsedHeroPower)) {
      Card *card = [Card byId:localId];
      if (card && [card.type isEqualToString:@"hero power"]) {
        if (player && [[player getTag:EGameTag_CURRENT_PLAYER] isEqualToNumber:@(1)]) {
          tagChangeHandler.playerUsedHeroPower = YES;
          DDLogInfo(@"player use hero power");
        }
        else if (opponent) {
          DDLogInfo(@"opponent use hero power");
          tagChangeHandler.opponentUsedHeroPower = YES;
        }
      }
    }
  }

  else if ([line isMatch:RX(@"BlockType=JOUST")]) {
    game.joustReveals = 2;
  }
}

@end
