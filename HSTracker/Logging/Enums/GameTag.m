/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "GameTag.h"

@implementation GameTag

+ (EGameTag)parse:(NSString *)rawValue
{
  if ([rawValue isEqualToString:@"IGNORE_DAMAGE"]) {return EGameTag_IGNORE_DAMAGE;}
  else if ([rawValue isEqualToString:@"TAG_SCRIPT_DATA_NUM_1"]) {return EGameTag_TAG_SCRIPT_DATA_NUM_1;}
  else if ([rawValue isEqualToString:@"TAG_SCRIPT_DATA_NUM_2"]) {return EGameTag_TAG_SCRIPT_DATA_NUM_2;}
  else if ([rawValue isEqualToString:@"TAG_SCRIPT_DATA_ENT_1"]) {return EGameTag_TAG_SCRIPT_DATA_ENT_1;}
  else if ([rawValue isEqualToString:@"TAG_SCRIPT_DATA_ENT_2"]) {return EGameTag_TAG_SCRIPT_DATA_ENT_2;}
  else if ([rawValue isEqualToString:@"MISSION_EVENT"]) {return EGameTag_MISSION_EVENT;}
  else if ([rawValue isEqualToString:@"TIMEOUT"]) {return EGameTag_TIMEOUT;}
  else if ([rawValue isEqualToString:@"TURN_START"]) {return EGameTag_TURN_START;}
  else if ([rawValue isEqualToString:@"TURN_TIMER_SLUSH"]) {return EGameTag_TURN_TIMER_SLUSH;}
  else if ([rawValue isEqualToString:@"PREMIUM"]) {return EGameTag_PREMIUM;}
  else if ([rawValue isEqualToString:@"GOLD_REWARD_STATE"]) {return EGameTag_GOLD_REWARD_STATE;}
  else if ([rawValue isEqualToString:@"PLAYSTATE"]) {return EGameTag_PLAYSTATE;}
  else if ([rawValue isEqualToString:@"LAST_AFFECTED_BY"]) {return EGameTag_LAST_AFFECTED_BY;}
  else if ([rawValue isEqualToString:@"STEP"]) {return EGameTag_STEP;}
  else if ([rawValue isEqualToString:@"TURN"]) {return EGameTag_TURN;}
  else if ([rawValue isEqualToString:@"FATIGUE"]) {return EGameTag_FATIGUE;}
  else if ([rawValue isEqualToString:@"CURRENT_PLAYER"]) {return EGameTag_CURRENT_PLAYER;}
  else if ([rawValue isEqualToString:@"FIRST_PLAYER"]) {return EGameTag_FIRST_PLAYER;}
  else if ([rawValue isEqualToString:@"RESOURCES_USED"]) {return EGameTag_RESOURCES_USED;}
  else if ([rawValue isEqualToString:@"RESOURCES"]) {return EGameTag_RESOURCES;}
  else if ([rawValue isEqualToString:@"HERO_ENTITY"]) {return EGameTag_HERO_ENTITY;}
  else if ([rawValue isEqualToString:@"MAXHANDSIZE"]) {return EGameTag_MAXHANDSIZE;}
  else if ([rawValue isEqualToString:@"STARTHANDSIZE"]) {return EGameTag_STARTHANDSIZE;}
  else if ([rawValue isEqualToString:@"PLAYER_ID"]) {return EGameTag_PLAYER_ID;}
  else if ([rawValue isEqualToString:@"TEAM_ID"]) {return EGameTag_TEAM_ID;}
  else if ([rawValue isEqualToString:@"TRIGGER_VISUAL"]) {return EGameTag_TRIGGER_VISUAL;}
  else if ([rawValue isEqualToString:@"RECENTLY_ARRIVED"]) {return EGameTag_RECENTLY_ARRIVED;}
  else if ([rawValue isEqualToString:@"PROTECTED"]) {return EGameTag_PROTECTED;}
  else if ([rawValue isEqualToString:@"PROTECTING"]) {return EGameTag_PROTECTING;}
  else if ([rawValue isEqualToString:@"DEFENDING"]) {return EGameTag_DEFENDING;}
  else if ([rawValue isEqualToString:@"PROPOSED_DEFENDER"]) {return EGameTag_PROPOSED_DEFENDER;}
  else if ([rawValue isEqualToString:@"ATTACKING"]) {return EGameTag_ATTACKING;}
  else if ([rawValue isEqualToString:@"PROPOSED_ATTACKER"]) {return EGameTag_PROPOSED_ATTACKER;}
  else if ([rawValue isEqualToString:@"ATTACHED"]) {return EGameTag_ATTACHED;}
  else if ([rawValue isEqualToString:@"EXHAUSTED"]) {return EGameTag_EXHAUSTED;}
  else if ([rawValue isEqualToString:@"DAMAGE"]) {return EGameTag_DAMAGE;}
  else if ([rawValue isEqualToString:@"HEALTH"]) {return EGameTag_HEALTH;}
  else if ([rawValue isEqualToString:@"ATK"]) {return EGameTag_ATK;}
  else if ([rawValue isEqualToString:@"COST"]) {return EGameTag_COST;}
  else if ([rawValue isEqualToString:@"ZONE"]) {return EGameTag_ZONE;}
  else if ([rawValue isEqualToString:@"CONTROLLER"]) {return EGameTag_CONTROLLER;}
  else if ([rawValue isEqualToString:@"OWNER"]) {return EGameTag_OWNER;}
  else if ([rawValue isEqualToString:@"DEFINITION"]) {return EGameTag_DEFINITION;}
  else if ([rawValue isEqualToString:@"ENTITY_ID"]) {return EGameTag_ENTITY_ID;}
  else if ([rawValue isEqualToString:@"HISTORY_PROXY"]) {return EGameTag_HISTORY_PROXY;}
  else if ([rawValue isEqualToString:@"COPY_DEATHRATTLE"]) {return EGameTag_COPY_DEATHRATTLE;}
  else if ([rawValue isEqualToString:@"COPY_DEATHRATTLE_INDEX"]) {return EGameTag_COPY_DEATHRATTLE_INDEX;}
  else if ([rawValue isEqualToString:@"ELITE"]) {return EGameTag_ELITE;}
  else if ([rawValue isEqualToString:@"MAXRESOURCES"]) {return EGameTag_MAXRESOURCES;}
  else if ([rawValue isEqualToString:@"CARD_SET"]) {return EGameTag_CARD_SET;}
  else if ([rawValue isEqualToString:@"CARDTEXT_INHAND"]) {return EGameTag_CARDTEXT_INHAND;}
  else if ([rawValue isEqualToString:@"CARDNAME"]) {return EGameTag_CARDNAME;}
  else if ([rawValue isEqualToString:@"CARD_ID"]) {return EGameTag_CARD_ID;}
  else if ([rawValue isEqualToString:@"DURABILITY"]) {return EGameTag_DURABILITY;}
  else if ([rawValue isEqualToString:@"SILENCED"]) {return EGameTag_SILENCED;}
  else if ([rawValue isEqualToString:@"WINDFURY"]) {return EGameTag_WINDFURY;}
  else if ([rawValue isEqualToString:@"TAUNT"]) {return EGameTag_TAUNT;}
  else if ([rawValue isEqualToString:@"STEALTH"]) {return EGameTag_STEALTH;}
  else if ([rawValue isEqualToString:@"SPELLPOWER"]) {return EGameTag_SPELLPOWER;}
  else if ([rawValue isEqualToString:@"DIVINE_SHIELD"]) {return EGameTag_DIVINE_SHIELD;}
  else if ([rawValue isEqualToString:@"CHARGE"]) {return EGameTag_CHARGE;}
  else if ([rawValue isEqualToString:@"NEXT_STEP"]) {return EGameTag_NEXT_STEP;}
  else if ([rawValue isEqualToString:@"CLASS"]) {return EGameTag_CLASS;}
  else if ([rawValue isEqualToString:@"CARDRACE"]) {return EGameTag_CARDRACE;}
  else if ([rawValue isEqualToString:@"FACTION"]) {return EGameTag_FACTION;}
  else if ([rawValue isEqualToString:@"CARDTYPE"]) {return EGameTag_CARDTYPE;}
  else if ([rawValue isEqualToString:@"RARITY"]) {return EGameTag_RARITY;}
  else if ([rawValue isEqualToString:@"STATE"]) {return EGameTag_STATE;}
  else if ([rawValue isEqualToString:@"SUMMONED"]) {return EGameTag_SUMMONED;}
  else if ([rawValue isEqualToString:@"FREEZE"]) {return EGameTag_FREEZE;}
  else if ([rawValue isEqualToString:@"ENRAGED"]) {return EGameTag_ENRAGED;}
  else if ([rawValue isEqualToString:@"OVERLOAD"]) {return EGameTag_OVERLOAD;}
  else if ([rawValue isEqualToString:@"LOYALTY"]) {return EGameTag_LOYALTY;}
  else if ([rawValue isEqualToString:@"DEATHRATTLE"]) {return EGameTag_DEATHRATTLE;}
  else if ([rawValue isEqualToString:@"BATTLECRY"]) {return EGameTag_BATTLECRY;}
  else if ([rawValue isEqualToString:@"SECRET"]) {return EGameTag_SECRET;}
  else if ([rawValue isEqualToString:@"COMBO"]) {return EGameTag_COMBO;}
  else if ([rawValue isEqualToString:@"CANT_HEAL"]) {return EGameTag_CANT_HEAL;}
  else if ([rawValue isEqualToString:@"CANT_DAMAGE"]) {return EGameTag_CANT_DAMAGE;}
  else if ([rawValue isEqualToString:@"CANT_SET_ASIDE"]) {return EGameTag_CANT_SET_ASIDE;}
  else if ([rawValue isEqualToString:@"CANT_REMOVE_FROM_GAME"]) {return EGameTag_CANT_REMOVE_FROM_GAME;}
  else if ([rawValue isEqualToString:@"CANT_READY"]) {return EGameTag_CANT_READY;}
  else if ([rawValue isEqualToString:@"CANT_EXHAUST"]) {return EGameTag_CANT_EXHAUST;}
  else if ([rawValue isEqualToString:@"CANT_ATTACK"]) {return EGameTag_CANT_ATTACK;}
  else if ([rawValue isEqualToString:@"CANT_TARGET"]) {return EGameTag_CANT_TARGET;}
  else if ([rawValue isEqualToString:@"CANT_DESTROY"]) {return EGameTag_CANT_DESTROY;}
  else if ([rawValue isEqualToString:@"CANT_DISCARD"]) {return EGameTag_CANT_DISCARD;}
  else if ([rawValue isEqualToString:@"CANT_PLAY"]) {return EGameTag_CANT_PLAY;}
  else if ([rawValue isEqualToString:@"CANT_DRAW"]) {return EGameTag_CANT_DRAW;}
  else if ([rawValue isEqualToString:@"INCOMING_HEALING_MULTIPLIER"]) {return EGameTag_INCOMING_HEALING_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"INCOMING_HEALING_ADJUSTMENT"]) {return EGameTag_INCOMING_HEALING_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"INCOMING_HEALING_CAP"]) {return EGameTag_INCOMING_HEALING_CAP;}
  else if ([rawValue isEqualToString:@"INCOMING_DAMAGE_MULTIPLIER"]) {return EGameTag_INCOMING_DAMAGE_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"INCOMING_DAMAGE_ADJUSTMENT"]) {return EGameTag_INCOMING_DAMAGE_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"INCOMING_DAMAGE_CAP"]) {return EGameTag_INCOMING_DAMAGE_CAP;}
  else if ([rawValue isEqualToString:@"CANT_BE_HEALED"]) {return EGameTag_CANT_BE_HEALED;}
  else if ([rawValue isEqualToString:@"CANT_BE_DAMAGED"]) {return EGameTag_CANT_BE_DAMAGED;}
  else if ([rawValue isEqualToString:@"CANT_BE_SET_ASIDE"]) {return EGameTag_CANT_BE_SET_ASIDE;}
  else if ([rawValue isEqualToString:@"CANT_BE_REMOVED_FROM_GAME"]) {return EGameTag_CANT_BE_REMOVED_FROM_GAME;}
  else if ([rawValue isEqualToString:@"CANT_BE_READIED"]) {return EGameTag_CANT_BE_READIED;}
  else if ([rawValue isEqualToString:@"CANT_BE_EXHAUSTED"]) {return EGameTag_CANT_BE_EXHAUSTED;}
  else if ([rawValue isEqualToString:@"CANT_BE_ATTACKED"]) {return EGameTag_CANT_BE_ATTACKED;}
  else if ([rawValue isEqualToString:@"CANT_BE_TARGETED"]) {return EGameTag_CANT_BE_TARGETED;}
  else if ([rawValue isEqualToString:@"CANT_BE_DESTROYED"]) {return EGameTag_CANT_BE_DESTROYED;}
  else if ([rawValue isEqualToString:@"CANT_BE_SUMMONING_SICK"]) {return EGameTag_CANT_BE_SUMMONING_SICK;}
  else if ([rawValue isEqualToString:@"FROZEN"]) {return EGameTag_FROZEN;}
  else if ([rawValue isEqualToString:@"JUST_PLAYED"]) {return EGameTag_JUST_PLAYED;}
  else if ([rawValue isEqualToString:@"LINKEDCARD"]) {return EGameTag_LINKEDCARD;}
  else if ([rawValue isEqualToString:@"ZONE_POSITION"]) {return EGameTag_ZONE_POSITION;}
  else if ([rawValue isEqualToString:@"CANT_BE_FROZEN"]) {return EGameTag_CANT_BE_FROZEN;}
  else if ([rawValue isEqualToString:@"COMBO_ACTIVE"]) {return EGameTag_COMBO_ACTIVE;}
  else if ([rawValue isEqualToString:@"CARD_TARGET"]) {return EGameTag_CARD_TARGET;}
  else if ([rawValue isEqualToString:@"NUM_CARDS_PLAYED_THIS_TURN"]) {return EGameTag_NUM_CARDS_PLAYED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"CANT_BE_TARGETED_BY_OPPONENTS"]) {return EGameTag_CANT_BE_TARGETED_BY_OPPONENTS;}
  else if ([rawValue isEqualToString:@"NUM_TURNS_IN_PLAY"]) {return EGameTag_NUM_TURNS_IN_PLAY;}
  else if ([rawValue isEqualToString:@"NUM_TURNS_LEFT"]) {return EGameTag_NUM_TURNS_LEFT;}
  else if ([rawValue isEqualToString:@"OUTGOING_DAMAGE_CAP"]) {return EGameTag_OUTGOING_DAMAGE_CAP;}
  else if ([rawValue isEqualToString:@"OUTGOING_DAMAGE_ADJUSTMENT"]) {return EGameTag_OUTGOING_DAMAGE_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"OUTGOING_DAMAGE_MULTIPLIER"]) {return EGameTag_OUTGOING_DAMAGE_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"OUTGOING_HEALING_CAP"]) {return EGameTag_OUTGOING_HEALING_CAP;}
  else if ([rawValue isEqualToString:@"OUTGOING_HEALING_ADJUSTMENT"]) {return EGameTag_OUTGOING_HEALING_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"OUTGOING_HEALING_MULTIPLIER"]) {return EGameTag_OUTGOING_HEALING_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"INCOMING_ABILITY_DAMAGE_ADJUSTMENT"]) {return EGameTag_INCOMING_ABILITY_DAMAGE_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"INCOMING_COMBAT_DAMAGE_ADJUSTMENT"]) {return EGameTag_INCOMING_COMBAT_DAMAGE_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"OUTGOING_ABILITY_DAMAGE_ADJUSTMENT"]) {return EGameTag_OUTGOING_ABILITY_DAMAGE_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"OUTGOING_COMBAT_DAMAGE_ADJUSTMENT"]) {return EGameTag_OUTGOING_COMBAT_DAMAGE_ADJUSTMENT;}
  else if ([rawValue isEqualToString:@"OUTGOING_ABILITY_DAMAGE_MULTIPLIER"]) {return EGameTag_OUTGOING_ABILITY_DAMAGE_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"OUTGOING_ABILITY_DAMAGE_CAP"]) {return EGameTag_OUTGOING_ABILITY_DAMAGE_CAP;}
  else if ([rawValue isEqualToString:@"INCOMING_ABILITY_DAMAGE_MULTIPLIER"]) {return EGameTag_INCOMING_ABILITY_DAMAGE_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"INCOMING_ABILITY_DAMAGE_CAP"]) {return EGameTag_INCOMING_ABILITY_DAMAGE_CAP;}
  else if ([rawValue isEqualToString:@"OUTGOING_COMBAT_DAMAGE_MULTIPLIER"]) {return EGameTag_OUTGOING_COMBAT_DAMAGE_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"OUTGOING_COMBAT_DAMAGE_CAP"]) {return EGameTag_OUTGOING_COMBAT_DAMAGE_CAP;}
  else if ([rawValue isEqualToString:@"INCOMING_COMBAT_DAMAGE_MULTIPLIER"]) {return EGameTag_INCOMING_COMBAT_DAMAGE_MULTIPLIER;}
  else if ([rawValue isEqualToString:@"INCOMING_COMBAT_DAMAGE_CAP"]) {return EGameTag_INCOMING_COMBAT_DAMAGE_CAP;}
  else if ([rawValue isEqualToString:@"CURRENT_SPELLPOWER"]) {return EGameTag_CURRENT_SPELLPOWER;}
  else if ([rawValue isEqualToString:@"ARMOR"]) {return EGameTag_ARMOR;}
  else if ([rawValue isEqualToString:@"MORPH"]) {return EGameTag_MORPH;}
  else if ([rawValue isEqualToString:@"IS_MORPHED"]) {return EGameTag_IS_MORPHED;}
  else if ([rawValue isEqualToString:@"TEMP_RESOURCES"]) {return EGameTag_TEMP_RESOURCES;}
  else if ([rawValue isEqualToString:@"OVERLOAD_OWED"]) {return EGameTag_OVERLOAD_OWED;}
  else if ([rawValue isEqualToString:@"NUM_ATTACKS_THIS_TURN"]) {return EGameTag_NUM_ATTACKS_THIS_TURN;}
  else if ([rawValue isEqualToString:@"NEXT_ALLY_BUFF"]) {return EGameTag_NEXT_ALLY_BUFF;}
  else if ([rawValue isEqualToString:@"MAGNET"]) {return EGameTag_MAGNET;}
  else if ([rawValue isEqualToString:@"FIRST_CARD_PLAYED_THIS_TURN"]) {return EGameTag_FIRST_CARD_PLAYED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"MULLIGAN_STATE"]) {return EGameTag_MULLIGAN_STATE;}
  else if ([rawValue isEqualToString:@"TAUNT_READY"]) {return EGameTag_TAUNT_READY;}
  else if ([rawValue isEqualToString:@"STEALTH_READY"]) {return EGameTag_STEALTH_READY;}
  else if ([rawValue isEqualToString:@"CHARGE_READY"]) {return EGameTag_CHARGE_READY;}
  else if ([rawValue isEqualToString:@"CANT_BE_TARGETED_BY_ABILITIES"]) {return EGameTag_CANT_BE_TARGETED_BY_ABILITIES;}
  else if ([rawValue isEqualToString:@"SHOULDEXITCOMBAT"]) {return EGameTag_SHOULDEXITCOMBAT;}
  else if ([rawValue isEqualToString:@"CREATOR"]) {return EGameTag_CREATOR;}
  else if ([rawValue isEqualToString:@"CANT_BE_DISPELLED"]) {return EGameTag_CANT_BE_DISPELLED;}
  else if ([rawValue isEqualToString:@"PARENT_CARD"]) {return EGameTag_PARENT_CARD;}
  else if ([rawValue isEqualToString:@"NUM_MINIONS_PLAYED_THIS_TURN"]) {return EGameTag_NUM_MINIONS_PLAYED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"PREDAMAGE"]) {return EGameTag_PREDAMAGE;}
  else if ([rawValue isEqualToString:@"ENCHANTMENT_BIRTH_VISUAL"]) {return EGameTag_ENCHANTMENT_BIRTH_VISUAL;}
  else if ([rawValue isEqualToString:@"ENCHANTMENT_IDLE_VISUAL"]) {return EGameTag_ENCHANTMENT_IDLE_VISUAL;}
  else if ([rawValue isEqualToString:@"CANT_BE_TARGETED_BY_HERO_POWERS"]) {return EGameTag_CANT_BE_TARGETED_BY_HERO_POWERS;}
  else if ([rawValue isEqualToString:@"HEALTH_MINIMUM"]) {return EGameTag_HEALTH_MINIMUM;}
  else if ([rawValue isEqualToString:@"TAG_ONE_TURN_EFFECT"]) {return EGameTag_TAG_ONE_TURN_EFFECT;}
  else if ([rawValue isEqualToString:@"SILENCE"]) {return EGameTag_SILENCE;}
  else if ([rawValue isEqualToString:@"COUNTER"]) {return EGameTag_COUNTER;}
  else if ([rawValue isEqualToString:@"HAND_REVEALED"]) {return EGameTag_HAND_REVEALED;}
  else if ([rawValue isEqualToString:@"ADJACENT_BUFF"]) {return EGameTag_ADJACENT_BUFF;}
  else if ([rawValue isEqualToString:@"FORCED_PLAY"]) {return EGameTag_FORCED_PLAY;}
  else if ([rawValue isEqualToString:@"LOW_HEALTH_THRESHOLD"]) {return EGameTag_LOW_HEALTH_THRESHOLD;}
  else if ([rawValue isEqualToString:@"IGNORE_DAMAGE_OFF"]) {return EGameTag_IGNORE_DAMAGE_OFF;}
  else if ([rawValue isEqualToString:@"SPELLPOWER_DOUBLE"]) {return EGameTag_SPELLPOWER_DOUBLE;}
  else if ([rawValue isEqualToString:@"HEALING_DOUBLE"]) {return EGameTag_HEALING_DOUBLE;}
  else if ([rawValue isEqualToString:@"NUM_OPTIONS_PLAYED_THIS_TURN"]) {return EGameTag_NUM_OPTIONS_PLAYED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"NUM_OPTIONS"]) {return EGameTag_NUM_OPTIONS;}
  else if ([rawValue isEqualToString:@"TO_BE_DESTROYED"]) {return EGameTag_TO_BE_DESTROYED;}
  else if ([rawValue isEqualToString:@"AURA"]) {return EGameTag_AURA;}
  else if ([rawValue isEqualToString:@"POISONOUS"]) {return EGameTag_POISONOUS;}
  else if ([rawValue isEqualToString:@"HERO_POWER_DOUBLE"]) {return EGameTag_HERO_POWER_DOUBLE;}
  else if ([rawValue isEqualToString:@"AI_MUST_PLAY"]) {return EGameTag_AI_MUST_PLAY;}
  else if ([rawValue isEqualToString:@"NUM_MINIONS_PLAYER_KILLED_THIS_TURN"]) {return EGameTag_NUM_MINIONS_PLAYER_KILLED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"NUM_MINIONS_KILLED_THIS_TURN"]) {return EGameTag_NUM_MINIONS_KILLED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"AFFECTED_BY_SPELL_POWER"]) {return EGameTag_AFFECTED_BY_SPELL_POWER;}
  else if ([rawValue isEqualToString:@"EXTRA_DEATHRATTLES"]) {return EGameTag_EXTRA_DEATHRATTLES;}
  else if ([rawValue isEqualToString:@"START_WITH_1_HEALTH"]) {return EGameTag_START_WITH_1_HEALTH;}
  else if ([rawValue isEqualToString:@"IMMUNE_WHILE_ATTACKING"]) {return EGameTag_IMMUNE_WHILE_ATTACKING;}
  else if ([rawValue isEqualToString:@"MULTIPLY_HERO_DAMAGE"]) {return EGameTag_MULTIPLY_HERO_DAMAGE;}
  else if ([rawValue isEqualToString:@"MULTIPLY_BUFF_VALUE"]) {return EGameTag_MULTIPLY_BUFF_VALUE;}
  else if ([rawValue isEqualToString:@"CUSTOM_KEYWORD_EFFECT"]) {return EGameTag_CUSTOM_KEYWORD_EFFECT;}
  else if ([rawValue isEqualToString:@"TOPDECK"]) {return EGameTag_TOPDECK;}
  else if ([rawValue isEqualToString:@"CANT_BE_TARGETED_BY_BATTLECRIES"]) {return EGameTag_CANT_BE_TARGETED_BY_BATTLECRIES;}
  else if ([rawValue isEqualToString:@"SHOWN_HERO_POWER"]) {return EGameTag_SHOWN_HERO_POWER;}
  else if ([rawValue isEqualToString:@"DEATHRATTLE_RETURN_ZONE"]) {return EGameTag_DEATHRATTLE_RETURN_ZONE;}
  else if ([rawValue isEqualToString:@"STEADY_SHOT_CAN_TARGET"]) {return EGameTag_STEADY_SHOT_CAN_TARGET;}
  else if ([rawValue isEqualToString:@"DISPLAYED_CREATOR"]) {return EGameTag_DISPLAYED_CREATOR;}
  else if ([rawValue isEqualToString:@"POWERED_UP"]) {return EGameTag_POWERED_UP;}
  else if ([rawValue isEqualToString:@"SPARE_PART"]) {return EGameTag_SPARE_PART;}
  else if ([rawValue isEqualToString:@"FORGETFUL"]) {return EGameTag_FORGETFUL;}
  else if ([rawValue isEqualToString:@"CAN_SUMMON_MAXPLUSONE_MINION"]) {return EGameTag_CAN_SUMMON_MAXPLUSONE_MINION;}
  else if ([rawValue isEqualToString:@"OBFUSCATED"]) {return EGameTag_OBFUSCATED;}
  else if ([rawValue isEqualToString:@"BURNING"]) {return EGameTag_BURNING;}
  else if ([rawValue isEqualToString:@"OVERLOAD_LOCKED"]) {return EGameTag_OVERLOAD_LOCKED;}
  else if ([rawValue isEqualToString:@"NUM_TIMES_HERO_POWER_USED_THIS_GAME"]) {return EGameTag_NUM_TIMES_HERO_POWER_USED_THIS_GAME;}
  else if ([rawValue isEqualToString:@"CURRENT_HEROPOWER_DAMAGE_BONUS"]) {return EGameTag_CURRENT_HEROPOWER_DAMAGE_BONUS;}
  else if ([rawValue isEqualToString:@"HEROPOWER_DAMAGE"]) {return EGameTag_HEROPOWER_DAMAGE;}
  else if ([rawValue isEqualToString:@"LAST_CARD_PLAYED"]) {return EGameTag_LAST_CARD_PLAYED;}
  else if ([rawValue isEqualToString:@"NUM_FRIENDLY_MINIONS_THAT_DIED_THIS_TURN"]) {return EGameTag_NUM_FRIENDLY_MINIONS_THAT_DIED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"NUM_CARDS_DRAWN_THIS_TURN"]) {return EGameTag_NUM_CARDS_DRAWN_THIS_TURN;}
  else if ([rawValue isEqualToString:@"AI_ONE_SHOT_KILL"]) {return EGameTag_AI_ONE_SHOT_KILL;}
  else if ([rawValue isEqualToString:@"EVIL_GLOW"]) {return EGameTag_EVIL_GLOW;}
  else if ([rawValue isEqualToString:@"HIDE_COST"]) {return EGameTag_HIDE_COST;}
  else if ([rawValue isEqualToString:@"INSPIRE"]) {return EGameTag_INSPIRE;}
  else if ([rawValue isEqualToString:@"RECEIVES_DOUBLE_SPELLDAMAGE_BONUS"]) {return EGameTag_RECEIVES_DOUBLE_SPELLDAMAGE_BONUS;}
  else if ([rawValue isEqualToString:@"HEROPOWER_ADDITIONAL_ACTIVATIONS"]) {return EGameTag_HEROPOWER_ADDITIONAL_ACTIVATIONS;}
  else if ([rawValue isEqualToString:@"HEROPOWER_ACTIVATIONS_THIS_TURN"]) {return EGameTag_HEROPOWER_ACTIVATIONS_THIS_TURN;}
  else if ([rawValue isEqualToString:@"REVEALED"]) {return EGameTag_REVEALED;}
  else if ([rawValue isEqualToString:@"NUM_FRIENDLY_MINIONS_THAT_DIED_THIS_GAME"]) {return EGameTag_NUM_FRIENDLY_MINIONS_THAT_DIED_THIS_GAME;}
  else if ([rawValue isEqualToString:@"CANNOT_ATTACK_HEROES"]) {return EGameTag_CANNOT_ATTACK_HEROES;}
  else if ([rawValue isEqualToString:@"LOCK_AND_LOAD"]) {return EGameTag_LOCK_AND_LOAD;}
  else if ([rawValue isEqualToString:@"TREASURE"]) {return EGameTag_TREASURE;}
  else if ([rawValue isEqualToString:@"SHADOWFORM"]) {return EGameTag_SHADOWFORM;}
  else if ([rawValue isEqualToString:@"NUM_FRIENDLY_MINIONS_THAT_ATTACKED_THIS_TURN"]) {return EGameTag_NUM_FRIENDLY_MINIONS_THAT_ATTACKED_THIS_TURN;}
  else if ([rawValue isEqualToString:@"NUM_RESOURCES_SPENT_THIS_GAME"]) {return EGameTag_NUM_RESOURCES_SPENT_THIS_GAME;}
  else if ([rawValue isEqualToString:@"CHOOSE_BOTH"]) {return EGameTag_CHOOSE_BOTH;}
  else if ([rawValue isEqualToString:@"ELECTRIC_CHARGE_LEVEL"]) {return EGameTag_ELECTRIC_CHARGE_LEVEL;}
  else if ([rawValue isEqualToString:@"HEAVILY_ARMORED"]) {return EGameTag_HEAVILY_ARMORED;}
  else if ([rawValue isEqualToString:@"DONT_SHOW_IMMUNE"]) {return EGameTag_DONT_SHOW_IMMUNE;}
  else if ([rawValue isEqualToString:@"Collectible"]) {return EGameTag_Collectible;}
  else if ([rawValue isEqualToString:@"InvisibleDeathrattle"]) {return EGameTag_InvisibleDeathrattle;}
  else if ([rawValue isEqualToString:@"OneTurnEffect"]) {return EGameTag_OneTurnEffect;}
  else if ([rawValue isEqualToString:@"ImmuneToSpellpower"]) {return EGameTag_ImmuneToSpellpower;}
  else if ([rawValue isEqualToString:@"AttackVisualType"]) {return EGameTag_AttackVisualType;}
  else if ([rawValue isEqualToString:@"DevState"]) {return EGameTag_DevState;}
  else if ([rawValue isEqualToString:@"GrantCharge"]) {return EGameTag_GrantCharge;}
  else if ([rawValue isEqualToString:@"HealTarget"]) {return EGameTag_HealTarget;}
  else if ([rawValue isEqualToString:@"CardTextInPlay"]) {return EGameTag_CardTextInPlay;}
  else if ([rawValue isEqualToString:@"TARGETING_ARROW_TEXT"]) {return EGameTag_TARGETING_ARROW_TEXT;}
  else if ([rawValue isEqualToString:@"ARTISTNAME"]) {return EGameTag_ARTISTNAME;}
  else if ([rawValue isEqualToString:@"FLAVORTEXT"]) {return EGameTag_FLAVORTEXT;}
  else if ([rawValue isEqualToString:@"HOW_TO_EARN"]) {return EGameTag_HOW_TO_EARN;}
  else if ([rawValue isEqualToString:@"HOW_TO_EARN_GOLDEN"]) {return EGameTag_HOW_TO_EARN_GOLDEN;}
  else if ([rawValue isEqualToString:@"DEATH_RATTLE"]) {return EGameTag_DEATH_RATTLE;}
  else if ([rawValue isEqualToString:@"DEATHRATTLE_SENDS_BACK_TO_DECK"]) {return EGameTag_DEATHRATTLE_SENDS_BACK_TO_DECK;}
  else if ([rawValue isEqualToString:@"RECALL"]) {return EGameTag_RECALL;}
  else if ([rawValue isEqualToString:@"RECALL_OWED"]) {return EGameTag_RECALL_OWED;}
  else if ([rawValue isEqualToString:@"TAG_HERO_POWER_DOUBLE"]) {return EGameTag_TAG_HERO_POWER_DOUBLE;}
  else if ([rawValue isEqualToString:@"TAG_AI_MUST_PLAY"]) {return EGameTag_TAG_AI_MUST_PLAY;}
  else if ([rawValue isEqualToString:@"OVERKILL"]) {return EGameTag_OVERKILL;}
  else if ([rawValue isEqualToString:@"DIVINE_SHIELD_READY"]) {return EGameTag_DIVINE_SHIELD_READY;}
  else if ([rawValue isEqualToString:@"EQUIPPED_WEAPON"]) {return EGameTag_EQUIPPED_WEAPON;}
  else {return (EGameTag) 0;}
}

+ (BOOL)exists:(NSNumber *)number
{
  NSInteger num = [number integerValue];
  if (num == EGameTag_IGNORE_DAMAGE) {return YES;}
  else if (num == EGameTag_TAG_SCRIPT_DATA_NUM_1) {return YES;}
  else if (num == EGameTag_TAG_SCRIPT_DATA_NUM_2) {return YES;}
  else if (num == EGameTag_TAG_SCRIPT_DATA_ENT_1) {return YES;}
  else if (num == EGameTag_TAG_SCRIPT_DATA_ENT_2) {return YES;}
  else if (num == EGameTag_MISSION_EVENT) {return YES;}
  else if (num == EGameTag_TIMEOUT) {return YES;}
  else if (num == EGameTag_TURN_START) {return YES;}
  else if (num == EGameTag_TURN_TIMER_SLUSH) {return YES;}
  else if (num == EGameTag_PREMIUM) {return YES;}
  else if (num == EGameTag_GOLD_REWARD_STATE) {return YES;}
  else if (num == EGameTag_PLAYSTATE) {return YES;}
  else if (num == EGameTag_LAST_AFFECTED_BY) {return YES;}
  else if (num == EGameTag_STEP) {return YES;}
  else if (num == EGameTag_TURN) {return YES;}
  else if (num == EGameTag_FATIGUE) {return YES;}
  else if (num == EGameTag_CURRENT_PLAYER) {return YES;}
  else if (num == EGameTag_FIRST_PLAYER) {return YES;}
  else if (num == EGameTag_RESOURCES_USED) {return YES;}
  else if (num == EGameTag_RESOURCES) {return YES;}
  else if (num == EGameTag_HERO_ENTITY) {return YES;}
  else if (num == EGameTag_MAXHANDSIZE) {return YES;}
  else if (num == EGameTag_STARTHANDSIZE) {return YES;}
  else if (num == EGameTag_PLAYER_ID) {return YES;}
  else if (num == EGameTag_TEAM_ID) {return YES;}
  else if (num == EGameTag_TRIGGER_VISUAL) {return YES;}
  else if (num == EGameTag_RECENTLY_ARRIVED) {return YES;}
  else if (num == EGameTag_PROTECTED) {return YES;}
  else if (num == EGameTag_PROTECTING) {return YES;}
  else if (num == EGameTag_DEFENDING) {return YES;}
  else if (num == EGameTag_PROPOSED_DEFENDER) {return YES;}
  else if (num == EGameTag_ATTACKING) {return YES;}
  else if (num == EGameTag_PROPOSED_ATTACKER) {return YES;}
  else if (num == EGameTag_ATTACHED) {return YES;}
  else if (num == EGameTag_EXHAUSTED) {return YES;}
  else if (num == EGameTag_DAMAGE) {return YES;}
  else if (num == EGameTag_HEALTH) {return YES;}
  else if (num == EGameTag_ATK) {return YES;}
  else if (num == EGameTag_COST) {return YES;}
  else if (num == EGameTag_ZONE) {return YES;}
  else if (num == EGameTag_CONTROLLER) {return YES;}
  else if (num == EGameTag_OWNER) {return YES;}
  else if (num == EGameTag_DEFINITION) {return YES;}
  else if (num == EGameTag_ENTITY_ID) {return YES;}
  else if (num == EGameTag_HISTORY_PROXY) {return YES;}
  else if (num == EGameTag_COPY_DEATHRATTLE) {return YES;}
  else if (num == EGameTag_COPY_DEATHRATTLE_INDEX) {return YES;}
  else if (num == EGameTag_ELITE) {return YES;}
  else if (num == EGameTag_MAXRESOURCES) {return YES;}
  else if (num == EGameTag_CARD_SET) {return YES;}
  else if (num == EGameTag_CARDTEXT_INHAND) {return YES;}
  else if (num == EGameTag_CARDNAME) {return YES;}
  else if (num == EGameTag_CARD_ID) {return YES;}
  else if (num == EGameTag_DURABILITY) {return YES;}
  else if (num == EGameTag_SILENCED) {return YES;}
  else if (num == EGameTag_WINDFURY) {return YES;}
  else if (num == EGameTag_TAUNT) {return YES;}
  else if (num == EGameTag_STEALTH) {return YES;}
  else if (num == EGameTag_SPELLPOWER) {return YES;}
  else if (num == EGameTag_DIVINE_SHIELD) {return YES;}
  else if (num == EGameTag_CHARGE) {return YES;}
  else if (num == EGameTag_NEXT_STEP) {return YES;}
  else if (num == EGameTag_CLASS) {return YES;}
  else if (num == EGameTag_CARDRACE) {return YES;}
  else if (num == EGameTag_FACTION) {return YES;}
  else if (num == EGameTag_CARDTYPE) {return YES;}
  else if (num == EGameTag_RARITY) {return YES;}
  else if (num == EGameTag_STATE) {return YES;}
  else if (num == EGameTag_SUMMONED) {return YES;}
  else if (num == EGameTag_FREEZE) {return YES;}
  else if (num == EGameTag_ENRAGED) {return YES;}
  else if (num == EGameTag_OVERLOAD) {return YES;}
  else if (num == EGameTag_LOYALTY) {return YES;}
  else if (num == EGameTag_DEATHRATTLE) {return YES;}
  else if (num == EGameTag_BATTLECRY) {return YES;}
  else if (num == EGameTag_SECRET) {return YES;}
  else if (num == EGameTag_COMBO) {return YES;}
  else if (num == EGameTag_CANT_HEAL) {return YES;}
  else if (num == EGameTag_CANT_DAMAGE) {return YES;}
  else if (num == EGameTag_CANT_SET_ASIDE) {return YES;}
  else if (num == EGameTag_CANT_REMOVE_FROM_GAME) {return YES;}
  else if (num == EGameTag_CANT_READY) {return YES;}
  else if (num == EGameTag_CANT_EXHAUST) {return YES;}
  else if (num == EGameTag_CANT_ATTACK) {return YES;}
  else if (num == EGameTag_CANT_TARGET) {return YES;}
  else if (num == EGameTag_CANT_DESTROY) {return YES;}
  else if (num == EGameTag_CANT_DISCARD) {return YES;}
  else if (num == EGameTag_CANT_PLAY) {return YES;}
  else if (num == EGameTag_CANT_DRAW) {return YES;}
  else if (num == EGameTag_INCOMING_HEALING_MULTIPLIER) {return YES;}
  else if (num == EGameTag_INCOMING_HEALING_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_INCOMING_HEALING_CAP) {return YES;}
  else if (num == EGameTag_INCOMING_DAMAGE_MULTIPLIER) {return YES;}
  else if (num == EGameTag_INCOMING_DAMAGE_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_INCOMING_DAMAGE_CAP) {return YES;}
  else if (num == EGameTag_CANT_BE_HEALED) {return YES;}
  else if (num == EGameTag_CANT_BE_DAMAGED) {return YES;}
  else if (num == EGameTag_CANT_BE_SET_ASIDE) {return YES;}
  else if (num == EGameTag_CANT_BE_REMOVED_FROM_GAME) {return YES;}
  else if (num == EGameTag_CANT_BE_READIED) {return YES;}
  else if (num == EGameTag_CANT_BE_EXHAUSTED) {return YES;}
  else if (num == EGameTag_CANT_BE_ATTACKED) {return YES;}
  else if (num == EGameTag_CANT_BE_TARGETED) {return YES;}
  else if (num == EGameTag_CANT_BE_DESTROYED) {return YES;}
  else if (num == EGameTag_CANT_BE_SUMMONING_SICK) {return YES;}
  else if (num == EGameTag_FROZEN) {return YES;}
  else if (num == EGameTag_JUST_PLAYED) {return YES;}
  else if (num == EGameTag_LINKEDCARD) {return YES;}
  else if (num == EGameTag_ZONE_POSITION) {return YES;}
  else if (num == EGameTag_CANT_BE_FROZEN) {return YES;}
  else if (num == EGameTag_COMBO_ACTIVE) {return YES;}
  else if (num == EGameTag_CARD_TARGET) {return YES;}
  else if (num == EGameTag_NUM_CARDS_PLAYED_THIS_TURN) {return YES;}
  else if (num == EGameTag_CANT_BE_TARGETED_BY_OPPONENTS) {return YES;}
  else if (num == EGameTag_NUM_TURNS_IN_PLAY) {return YES;}
  else if (num == EGameTag_NUM_TURNS_LEFT) {return YES;}
  else if (num == EGameTag_OUTGOING_DAMAGE_CAP) {return YES;}
  else if (num == EGameTag_OUTGOING_DAMAGE_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_OUTGOING_DAMAGE_MULTIPLIER) {return YES;}
  else if (num == EGameTag_OUTGOING_HEALING_CAP) {return YES;}
  else if (num == EGameTag_OUTGOING_HEALING_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_OUTGOING_HEALING_MULTIPLIER) {return YES;}
  else if (num == EGameTag_INCOMING_ABILITY_DAMAGE_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_INCOMING_COMBAT_DAMAGE_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_OUTGOING_ABILITY_DAMAGE_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_OUTGOING_COMBAT_DAMAGE_ADJUSTMENT) {return YES;}
  else if (num == EGameTag_OUTGOING_ABILITY_DAMAGE_MULTIPLIER) {return YES;}
  else if (num == EGameTag_OUTGOING_ABILITY_DAMAGE_CAP) {return YES;}
  else if (num == EGameTag_INCOMING_ABILITY_DAMAGE_MULTIPLIER) {return YES;}
  else if (num == EGameTag_INCOMING_ABILITY_DAMAGE_CAP) {return YES;}
  else if (num == EGameTag_OUTGOING_COMBAT_DAMAGE_MULTIPLIER) {return YES;}
  else if (num == EGameTag_OUTGOING_COMBAT_DAMAGE_CAP) {return YES;}
  else if (num == EGameTag_INCOMING_COMBAT_DAMAGE_MULTIPLIER) {return YES;}
  else if (num == EGameTag_INCOMING_COMBAT_DAMAGE_CAP) {return YES;}
  else if (num == EGameTag_CURRENT_SPELLPOWER) {return YES;}
  else if (num == EGameTag_ARMOR) {return YES;}
  else if (num == EGameTag_MORPH) {return YES;}
  else if (num == EGameTag_IS_MORPHED) {return YES;}
  else if (num == EGameTag_TEMP_RESOURCES) {return YES;}
  else if (num == EGameTag_OVERLOAD_OWED) {return YES;}
  else if (num == EGameTag_NUM_ATTACKS_THIS_TURN) {return YES;}
  else if (num == EGameTag_NEXT_ALLY_BUFF) {return YES;}
  else if (num == EGameTag_MAGNET) {return YES;}
  else if (num == EGameTag_FIRST_CARD_PLAYED_THIS_TURN) {return YES;}
  else if (num == EGameTag_MULLIGAN_STATE) {return YES;}
  else if (num == EGameTag_TAUNT_READY) {return YES;}
  else if (num == EGameTag_STEALTH_READY) {return YES;}
  else if (num == EGameTag_CHARGE_READY) {return YES;}
  else if (num == EGameTag_CANT_BE_TARGETED_BY_ABILITIES) {return YES;}
  else if (num == EGameTag_SHOULDEXITCOMBAT) {return YES;}
  else if (num == EGameTag_CREATOR) {return YES;}
  else if (num == EGameTag_CANT_BE_DISPELLED) {return YES;}
  else if (num == EGameTag_PARENT_CARD) {return YES;}
  else if (num == EGameTag_NUM_MINIONS_PLAYED_THIS_TURN) {return YES;}
  else if (num == EGameTag_PREDAMAGE) {return YES;}
  else if (num == EGameTag_ENCHANTMENT_BIRTH_VISUAL) {return YES;}
  else if (num == EGameTag_ENCHANTMENT_IDLE_VISUAL) {return YES;}
  else if (num == EGameTag_CANT_BE_TARGETED_BY_HERO_POWERS) {return YES;}
  else if (num == EGameTag_HEALTH_MINIMUM) {return YES;}
  else if (num == EGameTag_TAG_ONE_TURN_EFFECT) {return YES;}
  else if (num == EGameTag_SILENCE) {return YES;}
  else if (num == EGameTag_COUNTER) {return YES;}
  else if (num == EGameTag_HAND_REVEALED) {return YES;}
  else if (num == EGameTag_ADJACENT_BUFF) {return YES;}
  else if (num == EGameTag_FORCED_PLAY) {return YES;}
  else if (num == EGameTag_LOW_HEALTH_THRESHOLD) {return YES;}
  else if (num == EGameTag_IGNORE_DAMAGE_OFF) {return YES;}
  else if (num == EGameTag_SPELLPOWER_DOUBLE) {return YES;}
  else if (num == EGameTag_HEALING_DOUBLE) {return YES;}
  else if (num == EGameTag_NUM_OPTIONS_PLAYED_THIS_TURN) {return YES;}
  else if (num == EGameTag_NUM_OPTIONS) {return YES;}
  else if (num == EGameTag_TO_BE_DESTROYED) {return YES;}
  else if (num == EGameTag_AURA) {return YES;}
  else if (num == EGameTag_POISONOUS) {return YES;}
  else if (num == EGameTag_HERO_POWER_DOUBLE) {return YES;}
  else if (num == EGameTag_AI_MUST_PLAY) {return YES;}
  else if (num == EGameTag_NUM_MINIONS_PLAYER_KILLED_THIS_TURN) {return YES;}
  else if (num == EGameTag_NUM_MINIONS_KILLED_THIS_TURN) {return YES;}
  else if (num == EGameTag_AFFECTED_BY_SPELL_POWER) {return YES;}
  else if (num == EGameTag_EXTRA_DEATHRATTLES) {return YES;}
  else if (num == EGameTag_START_WITH_1_HEALTH) {return YES;}
  else if (num == EGameTag_IMMUNE_WHILE_ATTACKING) {return YES;}
  else if (num == EGameTag_MULTIPLY_HERO_DAMAGE) {return YES;}
  else if (num == EGameTag_MULTIPLY_BUFF_VALUE) {return YES;}
  else if (num == EGameTag_CUSTOM_KEYWORD_EFFECT) {return YES;}
  else if (num == EGameTag_TOPDECK) {return YES;}
  else if (num == EGameTag_CANT_BE_TARGETED_BY_BATTLECRIES) {return YES;}
  else if (num == EGameTag_SHOWN_HERO_POWER) {return YES;}
  else if (num == EGameTag_DEATHRATTLE_RETURN_ZONE) {return YES;}
  else if (num == EGameTag_STEADY_SHOT_CAN_TARGET) {return YES;}
  else if (num == EGameTag_DISPLAYED_CREATOR) {return YES;}
  else if (num == EGameTag_POWERED_UP) {return YES;}
  else if (num == EGameTag_SPARE_PART) {return YES;}
  else if (num == EGameTag_FORGETFUL) {return YES;}
  else if (num == EGameTag_CAN_SUMMON_MAXPLUSONE_MINION) {return YES;}
  else if (num == EGameTag_OBFUSCATED) {return YES;}
  else if (num == EGameTag_BURNING) {return YES;}
  else if (num == EGameTag_OVERLOAD_LOCKED) {return YES;}
  else if (num == EGameTag_NUM_TIMES_HERO_POWER_USED_THIS_GAME) {return YES;}
  else if (num == EGameTag_CURRENT_HEROPOWER_DAMAGE_BONUS) {return YES;}
  else if (num == EGameTag_HEROPOWER_DAMAGE) {return YES;}
  else if (num == EGameTag_LAST_CARD_PLAYED) {return YES;}
  else if (num == EGameTag_NUM_FRIENDLY_MINIONS_THAT_DIED_THIS_TURN) {return YES;}
  else if (num == EGameTag_NUM_CARDS_DRAWN_THIS_TURN) {return YES;}
  else if (num == EGameTag_AI_ONE_SHOT_KILL) {return YES;}
  else if (num == EGameTag_EVIL_GLOW) {return YES;}
  else if (num == EGameTag_HIDE_COST) {return YES;}
  else if (num == EGameTag_INSPIRE) {return YES;}
  else if (num == EGameTag_RECEIVES_DOUBLE_SPELLDAMAGE_BONUS) {return YES;}
  else if (num == EGameTag_HEROPOWER_ADDITIONAL_ACTIVATIONS) {return YES;}
  else if (num == EGameTag_HEROPOWER_ACTIVATIONS_THIS_TURN) {return YES;}
  else if (num == EGameTag_REVEALED) {return YES;}
  else if (num == EGameTag_NUM_FRIENDLY_MINIONS_THAT_DIED_THIS_GAME) {return YES;}
  else if (num == EGameTag_CANNOT_ATTACK_HEROES) {return YES;}
  else if (num == EGameTag_LOCK_AND_LOAD) {return YES;}
  else if (num == EGameTag_TREASURE) {return YES;}
  else if (num == EGameTag_SHADOWFORM) {return YES;}
  else if (num == EGameTag_NUM_FRIENDLY_MINIONS_THAT_ATTACKED_THIS_TURN) {return YES;}
  else if (num == EGameTag_NUM_RESOURCES_SPENT_THIS_GAME) {return YES;}
  else if (num == EGameTag_CHOOSE_BOTH) {return YES;}
  else if (num == EGameTag_ELECTRIC_CHARGE_LEVEL) {return YES;}
  else if (num == EGameTag_HEAVILY_ARMORED) {return YES;}
  else if (num == EGameTag_DONT_SHOW_IMMUNE) {return YES;}
  else if (num == EGameTag_Collectible) {return YES;}
  else if (num == EGameTag_InvisibleDeathrattle) {return YES;}
  else if (num == EGameTag_OneTurnEffect) {return YES;}
  else if (num == EGameTag_ImmuneToSpellpower) {return YES;}
  else if (num == EGameTag_AttackVisualType) {return YES;}
  else if (num == EGameTag_DevState) {return YES;}
  else if (num == EGameTag_GrantCharge) {return YES;}
  else if (num == EGameTag_HealTarget) {return YES;}
  else if (num == EGameTag_CardTextInPlay) {return YES;}
  else if (num == EGameTag_TARGETING_ARROW_TEXT) {return YES;}
  else if (num == EGameTag_ARTISTNAME) {return YES;}
  else if (num == EGameTag_FLAVORTEXT) {return YES;}
  else if (num == EGameTag_HOW_TO_EARN) {return YES;}
  else if (num == EGameTag_HOW_TO_EARN_GOLDEN) {return YES;}
  else if (num == EGameTag_DEATH_RATTLE) {return YES;}
  else if (num == EGameTag_DEATHRATTLE_SENDS_BACK_TO_DECK) {return YES;}
  else if (num == EGameTag_RECALL) {return YES;}
  else if (num == EGameTag_RECALL_OWED) {return YES;}
  else if (num == EGameTag_TAG_HERO_POWER_DOUBLE) {return YES;}
  else if (num == EGameTag_TAG_AI_MUST_PLAY) {return YES;}
  else if (num == EGameTag_OVERKILL) {return YES;}
  else if (num == EGameTag_DIVINE_SHIELD_READY) {return YES;}
  else if (num == EGameTag_EQUIPPED_WEAPON) {return YES;}
  else {return NO;}
}
@end
