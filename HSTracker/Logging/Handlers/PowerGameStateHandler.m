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
#import "CardType.h"
#import "NSString+HSTracker.h"
#import "Player.h"

static NSString *const GameEntityRegex = @"GameEntity EntityID=(\\d+)";
static NSString *const PlayerEntityRegex = @"Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)";
static NSString *const EntityNameRegex = @"TAG_CHANGE Entity=([\\w\\s]+\\w) tag=PLAYER_ID value=(\\d)";
static NSString *const TagChangeRegex = @"TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)";
static NSString *const CreationRegex = @"FULL_ENTITY - Creating ID=(\\d+) CardID=(\\w*)";
static NSString *const UpdatingEntityRegex = @"SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)";
static NSString *const CreationTagRegex = @"tag=(\\w+) value=(\\w+)";
static NSString *const ActionStartRegex = @".*ACTION_START.*id=(\\d*).*cardId=(\\w*).*BlockType=(POWER|TRIGGER).*Target=(.+)";
static TagChangeHandler *tagChangeHandler = nil;
static NSInteger currentEntityId = NSNotFound;
static Entity *currentEntity = nil;

@implementation PowerGameStateHandler

+ (void)handle:(NSString *)line
{
  if (tagChangeHandler == nil) {tagChangeHandler = [TagChangeHandler new];}
  Entity *entity = nil;

  Game *game = [Game instance];

  // current game
  if ([line isMatch:RX(GameEntityRegex)]) {
    [game gameStart];

    RxMatch *match = [line firstMatchWithDetails:RX(GameEntityRegex)];
    //DDLogVerbose(@"GameEntityRegex %@ -> %@", GameEntityRegex, match.groups[1]);
    NSInteger id = [((RxMatchGroup *) match.groups[1]).value integerValue];
    if (!game.entities[@(id)]) {
      game.entities[@(id)] = [[Entity alloc] initWithId:id];
    }
    currentEntityId = id;
  }

    // players
  else if ([line isMatch:RX(PlayerEntityRegex)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(PlayerEntityRegex)];
    //DDLogVerbose(@"PlayerEntityRegex %@ -> %@", PlayerEntityRegex, match.groups[1]);
    NSInteger id = [((RxMatchGroup *) match.groups[1]).value integerValue];

    if (!game.entities[@(id)]) {
      game.entities[@(id)] = [[Entity alloc] initWithId:id];
    }
    currentEntityId = id;
  }

  else if ([line isMatch:RX(TagChangeRegex)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(TagChangeRegex)];
    //DDLogVerbose(@"TagChangeRegex %@ -> %@", TagChangeRegex, match.groups);
    NSString *rawEntity = [((RxMatchGroup *) match.groups[1]).value stringByReplacingOccurrencesOfString:@"UNKNOWN ENTITY "
                                                                                              withString:@""];
    NSString *tag = ((RxMatchGroup *) match.groups[2]).value;
    NSString *value = ((RxMatchGroup *) match.groups[3]).value;

    if ([rawEntity isMatch:RX(@"^\\[")] && [tagChangeHandler isEntity:rawEntity]) {
      NSDictionary *dict = [tagChangeHandler parseEntity:rawEntity];
      NSInteger id = [dict[@"id"] isEqual:[NSNull null]] ? NSNotFound : [dict[@"id"] integerValue];
      [tagChangeHandler tagChange:tag id:id rawValue:value];
    }
    else if ([rawEntity isMatch:RX(@"\\d+")]) {
      NSInteger id = [rawEntity integerValue];
      [tagChangeHandler tagChange:tag id:id rawValue:value];
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
          tmpEntity = [[Entity alloc] initWithId:(game.tmpEntities.count + 1)];
          tmpEntity.name = rawEntity;
          [game.tmpEntities addObject:tmpEntity];
        }

        EGameTag _tag;
        [GameTag tryParse:tag out:&_tag];
        NSInteger tagValue = [tagChangeHandler parseTag:_tag rawValue:value];
        [tmpEntity setValue:tagValue forTag:_tag];
        if ([tmpEntity hasTag:EGameTag_ENTITY_ID]) {
          NSInteger id = [tmpEntity getTag:EGameTag_ENTITY_ID];
          if (game.entities[@(id)]) {
            ((Entity *) game.entities[@(id)]).name = tmpEntity.name;
            for (NSNumber *key in [tmpEntity.tags allKeys]) {
              [((Entity *) game.entities[@(id)]) setValue:[tmpEntity.tags[key] integerValue]
                                                   forTag:[key integerValue]];
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

    if ([line isMatch:RX(EntityNameRegex)]) {
      match = [line firstMatchWithDetails:RX(EntityNameRegex)];
      //DDLogVerbose(@"EntityNameRegex %@ -> %@", EntityNameRegex, match.groups);
      NSString *name = ((RxMatchGroup *) match.groups[1]).value;
      NSInteger player = [((RxMatchGroup *) match.groups[2]).value integerValue];

      for (Entity *ent in [game.entities allValues]) {
        if ([ent hasTag:EGameTag_PLAYER_ID] && [ent getTag:EGameTag_PLAYER_ID] == player) {
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
  }

  else if ([line isMatch:RX(CreationRegex)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(CreationRegex)];
    //DDLogVerbose(@"CreationRegex %@ -> %@", CreationRegex, match.groups);
    NSInteger id = [((RxMatchGroup *) match.groups[1]).value integerValue];
    NSString *cardId = ((RxMatchGroup *) match.groups[2]).value;

    if (!game.entities[@(id)]) {
      entity = [[Entity alloc] initWithId:id];
      entity.cardId = cardId;
      game.entities[@(id)] = entity;
    }
    currentEntityId = id;
    tagChangeHandler.currentEntityHasCardId = cardId != nil && ![cardId isEmpty];
  }

  else if ([line isMatch:RX(UpdatingEntityRegex)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(UpdatingEntityRegex)];
    //DDLogVerbose(@"UpdatingEntityRegex %@ -> %@", UpdatingEntityRegex, match);
    NSString *tmpEntity = ((RxMatchGroup *) match.groups[1]).value;
    NSString *cardId = ((RxMatchGroup *) match.groups[2]).value;

    NSInteger entityId = NSNotFound;
    if ([tmpEntity isMatch:RX(@"^\\[")] && [tagChangeHandler isEntity:tmpEntity]) {
      NSDictionary *dict = [tagChangeHandler parseEntity:tmpEntity];
      entityId = [dict[@"id"] integerValue];
    }
    else if ([tmpEntity isMatch:RX(@"\\d+")]) {
      entityId = [tmpEntity integerValue];
    }
    if (entityId != NSNotFound) {
      if (!game.entities[@(entityId)]) {
        entity = [[Entity alloc] initWithId:entityId];
        game.entities[@(entityId)] = entity;
      }
      ((Entity *) game.entities[@(entityId)]).cardId = cardId;
    }

    if (game.joustReveals > 0) {
      currentEntity = game.entities[@(entityId)];
      if (currentEntity) {
        if ([currentEntity isControllerBy:game.opponent.id]) {
          [game opponentJoust:currentEntity card:cardId turn:[game turnNumber]];
        }
        else if ([currentEntity isControllerBy:game.player.id]) {
          [game playerJoust:currentEntity card:cardId turn:[game turnNumber]];
        }
      }
    }
  }

  else if ([line isMatch:RX(CreationTagRegex)] && ![line isMatch:RX(@"HIDE_ENTITY")]) {
    RxMatch *match = [line firstMatchWithDetails:RX(CreationTagRegex)];
    //DDLogVerbose(@"Tag %@ -> %@", Tag, match);
    NSString *tag = ((RxMatchGroup *) match.groups[1]).value;
    NSString *value = ((RxMatchGroup *) match.groups[2]).value;
    [tagChangeHandler tagChange:tag
                             id:currentEntityId
                       rawValue:value];
  }

  else if ([line isMatch:RX(@"Begin Spectating")] || [line isMatch:RX(@"Start Spectator")]) {
    game.gameMode = EGameMode_Spectator;
  }

  else if ([line isMatch:RX(@"End Spectator")]) {
    game.gameMode = EGameMode_Spectator;
    [game gameEnd];
  }

  else if ([line isMatch:RX(ActionStartRegex)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(ActionStartRegex)];
    //DDLogVerbose(@"ActionStartRegex %@ -> %@", ActionStartRegex, match);
    NSInteger actionStartingEntityId = [((RxMatchGroup *) match.groups[1]).value integerValue];
    NSString *actionStartingCardId = ((RxMatchGroup *) match.groups[2]).value;
    //NSString *target = ((RxMatchGroup *) match.groups[3]).value;

    Entity *player, *opponent;
    for (Entity *ent in [game.entities allValues]) {
      if ([ent getTag:EGameTag_PLAYER_ID] == game.player.id) {
        player = ent;
      }
      else if ([ent getTag:EGameTag_PLAYER_ID] == game.opponent.id) {
        opponent = ent;
      }
    }

    Entity *actionEntity;
    if (actionStartingCardId == nil || [actionStartingCardId isEmpty]) {
      if (game.entities[@(actionStartingEntityId)]) {
        actionEntity = game.entities[@(actionStartingEntityId)];
        actionStartingCardId = actionEntity.cardId;
      }
    }

    if (game.entities[@(actionStartingEntityId)]) {
      actionEntity = game.entities[@(actionStartingEntityId)];

      if ([actionEntity getTag:EGameTag_CONTROLLER] == game.player.id
        && [actionEntity getTag:EGameTag_CARDTYPE] == ECardType_SPELL) {
        //NSInteger targetEntityId = [actionEntity getTag:EGameTag_CARD_TARGET];
        //Entity *targetEntity;
        //var targetsMinion = game.Entities.TryGetValue(targetEntityId, out targetEntity) && targetEntity.IsMinion;
        //gameState.GameHandler.HandlePlayerSpellPlayed(targetsMinion);
      }
    }

    if (actionStartingCardId == nil || [actionStartingCardId isEmpty]) {
      return;
    }

    NSString *type = ((RxMatchGroup *) match.groups[3]).value;
    if ([type isEqualToString:@"TRIGGER"]) {
      // TODO
    }
    else {
      // TODO
      Card *card = [Card byId:actionStartingCardId];
      if (card && [card.type isEqualToString:@"hero power"]) {
        if (player && [player getTag:EGameTag_CURRENT_PLAYER] == 1) {
          tagChangeHandler.playerUsedHeroPower = YES;
          DDLogInfo(@"player use hero power");
        }
        else if (opponent) {
          DDLogInfo(@"opponent use hero power");
          tagChangeHandler.opponentUsedHeroPower = YES;
        }
      }
    }


    /*if ((localId == nil || [localId isEmpty]) && id != NSNotFound) {
      entity = game.entities[@(id)];
      localId = entity.cardId;
    }

    if ([localId isEqualToString:@"BRM_007"]) { // Gang Up
      NSString *cardId;
      if ([target isMatch:RX(@"^\\[")] && [tagChangeHandler isEntity:target]) {
        if ([target isMatch:RX(@"cardId=(\\w+)")]) {
          cardId = [target firstMatch:RX(@"cardId=(\\w+)")];
        }
      }

      if (player != nil && [player getTag:EGameTag_CURRENT_PLAYER] == 1) {
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
      if (player != nil && [player getTag:EGameTag_CURRENT_PLAYER] == 1) {
        [game opponentGetToDeck:@"GVG_056t" turn:[game turnNumber]];
      }
      else {
        [game playerGetToDeck:@"GVG_056t" turn:[game turnNumber]];
      }
    }

    else if ((player && [player getTag:EGameTag_CURRENT_PLAYER] == 1 && tagChangeHandler.playerUsedHeroPower) ||
      (opponent && [opponent getTag:EGameTag_CURRENT_PLAYER] == 1 && !tagChangeHandler.opponentUsedHeroPower)) {
      Card *card = [Card byId:localId];
      if (card && [card.type isEqualToString:@"hero power"]) {
        if (player && [player getTag:EGameTag_CURRENT_PLAYER] == 1) {
          tagChangeHandler.playerUsedHeroPower = YES;
          DDLogInfo(@"player use hero power");
        }
        else if (opponent) {
          DDLogInfo(@"opponent use hero power");
          tagChangeHandler.opponentUsedHeroPower = YES;
        }
      }
    }*/
  }

  else if ([line isMatch:RX(@"BlockType=JOUST")]) {
    game.joustReveals = 2;
  }
}

@end
