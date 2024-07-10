/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 19/02/16.
 */

import Foundation

enum GameTag: Int, CaseIterable, Codable {
    case ignore_damage = 1,
    tag_script_data_num_1 = 2,
    tag_script_data_num_2 = 3,
    tag_script_data_ent_1 = 4,
    tag_script_data_ent_2 = 5,
    mission_event = 6,
    timeout = 7,
    turn_start = 8,
    turn_timer_slush = 9,
    premium = 12,
    gold_reward_state = 13,
    playstate = 17,
    last_affected_by = 18,
    step = 19,
    turn = 20,
    fatigue = 22,
    current_player = 23,
    first_player = 24,
    resources_used = 25,
    resources = 26,
    hero_entity = 27,
    maxhandsize = 28,
    starthandsize = 29,
    player_id = 30,
    team_id = 31,
    trigger_visual = 32,
    recently_arrived = 33,
    protected = 34,
    protecting = 35,
    defending = 36,
    proposed_defender = 37,
    attacking = 38,
    proposed_attacker = 39,
    attached = 40,
    exhausted = 43,
    damage = 44,
    health = 45,
    atk = 47,
    cost = 48,
    zone = 49,
    controller = 50,
    owner = 51,
    definition = 52,
    entity_id = 53,
    history_proxy = 54,
    copy_deathrattle = 55,
    copy_deathrattle_index = 56,
    elite = 114,
    maxresources = 176,
    card_set = 183,
    cardtext = 184,
    cardname = 185,
    card_id = 186,
    durability = 187,
    silenced = 188,
    windfury = 189,
    taunt = 190,
    stealth = 191,
    spellpower = 192,
    divine_shield = 194,
    charge = 197,
    next_step = 198,
    `class` = 199,
    cardrace = 200,
    faction = 201,
    cardtype = 202,
    rarity = 203,
    state = 204,
    summoned = 205,
    freeze = 208,
    enraged = 212,
    //overload = 215,
    recall = 215,
    loyalty = 216,
    deathrattle = 217,
    //death_rattle = 217,
    battlecry = 218,
    secret = 219,
    combo = 220,
    cant_heal = 221,
    cant_damage = 222,
    cant_set_aside = 223,
    cant_remove_from_game = 224,
    cant_ready = 225,
    cant_exhaust = 226,
    cant_attack = 227,
    cant_target = 228,
    cant_destroy = 229,
    cant_discard = 230,
    cant_play = 231,
    cant_draw = 232,
    incoming_healing_multiplier = 233,
    incoming_healing_adjustment = 234,
    incoming_healing_cap = 235,
    incoming_damage_multiplier = 236,
    incoming_damage_adjustment = 237,
    incoming_damage_cap = 238,
    cant_be_healed = 239,
    immune = 240,
    //cant_be_damaged = 240,
    cant_be_set_aside = 241,
    cant_be_removed_from_game = 242,
    cant_be_readied = 243,
    cant_be_exhausted = 244,
    cant_be_attacked = 245,
    cant_be_targeted = 246,
    cant_be_destroyed = 247,
    attackvisualtype = 251,
    cardtextinplay = 252,
    cant_be_summoning_sick = 253,
    frozen = 260,
    just_played = 261,
    //linkedcard = 262,
    linked_entity = 262,
    zone_position = 263,
    cant_be_frozen = 264,
    combo_active = 266,
    card_target = 267,
    devstate = 268,
    num_cards_played_this_turn = 269,
    cant_be_targeted_by_opponents = 270,
    num_turns_in_play = 271,
    num_turns_left = 272,
    num_turns_in_hand = 273,
    outgoing_damage_adjustment = 274,
    outgoing_damage_multiplier = 275,
    outgoing_healing_cap = 276,
    outgoing_healing_adjustment = 277,
    outgoing_healing_multiplier = 278,
    incoming_ability_damage_adjustment = 279,
    incoming_combat_damage_adjustment = 280,
    outgoing_ability_damage_adjustment = 281,
    outgoing_combat_damage_adjustment = 282,
    outgoing_ability_damage_multiplier = 283,
    outgoing_ability_damage_cap = 284,
    incoming_ability_damage_multiplier = 285,
    incoming_ability_damage_cap = 286,
    outgoing_combat_damage_multiplier = 287,
    outgoing_combat_damage_cap = 288,
    incoming_combat_damage_multiplier = 289,
    incoming_combat_damage_cap = 290,
    current_spellpower = 291,
    armor = 292,
    morph = 293,
    is_morphed = 294,
    temp_resources = 295,
    //overload_owed = 296,
    recall_owed = 296,
    num_attacks_this_turn = 297,
    next_ally_buff = 302,
    magnet = 303,
    first_card_played_this_turn = 304,
    mulligan_state = 305,
    taunt_ready = 306,
    stealth_ready = 307,
    charge_ready = 308,
    cant_be_targeted_by_abilities = 311,
    //cant_be_targeted_by_spells = 311,
    shouldexitcombat = 312,
    creator = 313,
    //cant_be_dispelled = 314,
    divine_shield_ready = 314,
    //cant_be_silenced = 314,
    parent_card = 316,
    num_minions_played_this_turn = 317,
    predamage = 318,
    collectible = 321,
    targeting_arrow_text = 325,
    enchantment_birth_visual = 330,
    enchantment_idle_visual = 331,
    cant_be_targeted_by_hero_powers = 332,
    weapon = 334,
    invisibledeathrattle = 335,
    health_minimum = 337,
    tag_one_turn_effect = 338,
    silence = 339,
    counter = 340,
    artistname = 342,
    localizationnotes = 344,
    hand_revealed = 348,
    immunetospellpower = 349,
    adjacent_buff = 350,
    flavortext = 351,
    forced_play = 352,
    low_health_threshold = 353,
    ignore_damage_off = 354,
    grantcharge = 355,
    spellpower_double = 356,
    healing_double = 357,
    num_options_played_this_turn = 358,
    num_options = 359,
    to_be_destroyed = 360,
    healtarget = 361,
    aura = 362,
    poisonous = 363,
    how_to_earn = 364,
    how_to_earn_golden = 365,
    tag_hero_power_double = 366,
    //hero_power_double = 366,
    //ai_must_play = 367,
    tag_ai_must_play = 367,
    num_minions_player_killed_this_turn = 368,
    num_minions_killed_this_turn = 369,
    affected_by_spell_power = 370,
    extra_deathrattles = 371,
    start_with_1_health = 372,
    immune_while_attacking = 373,
    multiply_hero_damage = 374,
    multiply_buff_value = 375,
    custom_keyword_effect = 376,
    topdeck = 377,
    cant_be_targeted_by_battlecries = 379,
    hero_power = 380,
    //overkill = 380,
    //shown_hero_power = 380,
    deathrattle_sends_back_to_deck = 382,
    //deathrattle_return_zone = 382,
    steady_shot_can_target = 383,
    displayed_creator = 385,
    powered_up = 386,
    spare_part = 388,
    forgetful = 389,
    can_summon_maxplusone_minion = 390,
    obfuscated = 391,
    burning = 392,
    overload_locked = 393,
    num_times_hero_power_used_this_game = 394,
    current_heropower_damage_bonus = 395,
    heropower_damage = 396,
    last_card_played = 397,
    num_friendly_minions_that_died_this_turn = 398,
    num_cards_drawn_this_turn = 399,
    ai_one_shot_kill = 400,
    evil_glow = 401,
    //hide_cost = 402,
    hide_stats = 402,
    inspire = 403,
    receives_double_spelldamage_bonus = 404,
    heropower_additional_activations = 405,
    heropower_activations_this_turn = 406,
    revealed = 410,
    num_friendly_minions_that_died_this_game = 412,
    cannot_attack_heroes = 413,
    lock_and_load = 414,
    discover = 415,
//    treasure = 415,
    shadowform = 416,
    num_friendly_minions_that_attacked_this_turn = 417,
    num_resources_spent_this_game = 418,
    choose_both = 419,
    electric_charge_level = 420,
    heavily_armored = 421,
    dont_show_immune = 422,
    ritual = 424,
    prehealing = 425,
    appear_functionally_dead = 426,
    overload_this_game = 427,
    spells_cost_health = 431,
    history_proxy_no_big_card = 432,
    proxy_cthun = 434,
    transformed_from_card = 435,
    cthun = 436,
    cast_random_spells = 437,
    shifting = 438,
    jade_golem = 441,
    embrace_the_shadow = 442,
    choose_one = 443,
    extra_attacks_this_turn = 444,
    seen_cthun = 445,
    minion_type_reference = 447,
    untouchable = 448,
    red_mana_crystals = 449,
    score_labelid_1 = 450,
    score_value_1 = 451,
    score_labelid_2 = 452,
    score_value_2 = 453,
    score_labelid_3 = 454,
    score_value_3 = 455,
    cant_be_fatigued = 456,
    autoattack = 457,
    arms_dealing = 458,
    pending_evolutions = 461,
    quest = 462,
    tag_last_known_cost_in_hand = 466,
    defining_enchantment = 469,
    finish_attack_spell_on_damage = 470,
    modular_entity_part_1 = 471,
    modular_entity_part_2 = 472,
    modify_definition_attack = 473,
    modify_definition_health = 474,
    modify_definition_cost = 475,
    multiple_classes = 476,
    all_targets_random = 477,
    multi_class_group = 480,
    card_costs_health = 481,
    grimy_goons = 482,
    jade_lotus = 483,
    kabal = 484,
    additional_play_reqs_1 = 515,
    additional_play_reqs_2 = 516,
    elemental_powered_up = 532,
    quest_progress = 534,
    quest_progress_total = 535,
    quest_contributor = 541,
    adapt = 546,
    is_current_turn_an_extra_turn = 547,
    extra_turns_taken_this_game = 548,
    shifting_minion = 549,
    shifting_weapon = 550,
    death_knight = 554,
    boss = 556,
    stampede = 564,
    is_vampire = 680,
    corrupted = 681,
    lifesteal = 685,
    override_emote_0 = 740,
    override_emote_1 = 741,
    override_emote_2 = 742,
    override_emote_3 = 743,
    override_emote_4 = 744,
    override_emote_5 = 745,
    score_footerid = 751,
    recruit = 763,
    hero_power_disabled = 777,
    valeerashadow = 779,
    overridecardname = 781,
    overridecardtextbuilder = 782,
    dungeon_passive_buff = 783,
    rush = 791,
    hidden_choice = 813,
    zombeast = 823,
    modular = 849,
    overkill = 923,
    literally_unplayable = 1020,
    whizbang_deck_id = 1048,
    shrine = 1057,
    reborn = 1085,
    quest_reward_database_id = 1089,
    proxy_galakrond = 1190,
    sidequest = 1192,
    mega_windfury = 1207,
    creator_dbid = 1284,
    outcast = 1333,
    bacon_dummy_player = 1349,
    allow_move_minion = 1356,
    next_opponent_player_id = 1360,
    invoke_counter = 1366,
    player_leaderboard_place = 1373,
    player_tech_level = 1377,
    bacon_hero_power_activated = 1398,
    tech_level = 1440,
    player_triples = 1447,
    is_bacon_pool_minion = 1456,
    bacon_hero_can_be_drafted = 1491,
    dormant = 1518,
    copied_from_entity_id = 1565,
    spell_school = 1635,
    lettuce_controller = 1653,
    lettuce_ability_owner = 1654,
    lettuce_cooldown_config = 1669,
    lettuce_current_cooldown = 1670,
    lettuce_ability_tile_visual_all_visible = 1697,
    lettuce_ability_tile_visual_self_only = 1698,
    fake_zone = 1702,
    fake_zone_position = 1703,
    tradeable = 1720,
    questline = 1725,
    sigil = 1749,
    bacon_bloodgembuffatkvalue = 1844,
    lettuce_is_equipment = 1855,
    honorable_kill = 1920,
    questline_part = 1993,
    dont_show_in_history = 2015,
    gametag_2022 = 2022,
    bacon_skin = 2038,
    bacon_skin_parent_id = 2039,
    gametag_2088 = 2088,
    bacon_combat_damage_cap = 2089,
    lettuce_show_opposing_fake_hand = 2224,
    objective = 2311,
    dredge = 2332,
    bacon_player_num_hero_buddies_gained = 2346,
    bacon_buddy_enabled = 2518,
    immolatestage = 2600,
    bacon_card_dbid_reward = 2673,
    secret_locked = 2676,
    bacon_hero_quest_reward_database_id = 2713,
    bacon_hero_heropower_quest_reward_database_id = 2714,
    bacon_hero_quest_reward_completed = 2715,
    bacon_hero_heropower_quest_reward_completed = 2716,
    titan = 2772,
    gametag_2822 = 2822,
    bacon_bloodgembuffhealthvalue = 2827,
    venomous = 2853,
    gametag_2878 = 2878,
    bacon_global_anomaly_dbid = 2897,
    cthun_health_buff = 3053,
    cthun_attack_buff = 3054,
    bacon_duo_team_id = 3095,
    titan_ability_used_1 = 3140,
    titan_ability_used_2 = 3141,
    titan_ability_used_3 = 3142,
    is_bacon_duos_exclusive = 3166,
    current_excavate_tier = 3249,
    zilliax_customizable_cosmeticmodule = 3376,
    zilliax_customizable_functionalmodule = 3377,
    bacon_combat_damage_cap_enabled = 3403,
    gametag_3533 = 3533

    static var lookup = [String: GameTag]()
    
    static func initialize() {
        for _enum in GameTag.allCases {
            GameTag.lookup["\(_enum)"] = _enum
        }
    }
    
    init?(rawString: String) {
        let string = rawString.lowercased()
        if let _enum = GameTag.lookup[string] {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = GameTag(rawValue: value) {
            self = _enum
            return
        }
        return nil
    }
}
