class TagChangeHandler
  attr_accessor :current_entity_has_card_id, :player_used_hero_power, :opponent_used_hero_power

  def tag_change(raw_tag, id, raw_value, recurse=false)

    unless Game.instance.entities.has_key? id
      Game.instance.entities[id] = Entity.new(id)
    end

    tag = GameTag.parse(raw_tag)
    if tag.nil?
      if raw_tag.is_a?(Fixnum) && GameTag.exists?(raw_tag)
        tag = raw_tag
      elsif raw_tag.is_a?(String) && raw_tag.is_i? && GameTag.exists?(raw_tag.to_i)
        tag = raw_tag.to_i
      end
    end
    value = parse_tag(tag, raw_value)

    prev_zone = Game.instance.entities[id].tag(GameTag::ZONE)
    Game.instance.entities[id].set_tag(tag, value)

    if tag == GameTag::CONTROLLER && !Game.instance.wait_controller.nil? && Game.instance.player_id.nil?
      player_1 = Game.instance.entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == 1 }.values.first
      player_2 = Game.instance.entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == 2 }.values.first

      if current_entity_has_card_id
        player_1.is_player = (value == 1) if player_1
        player_2.is_player = (value != 1) if player_2

        Game.instance.player_id = value
        Game.instance.opponent_id = value % 2 + 1

      else
        player_1.is_player = (value != 1) if player_1
        player_2.is_player = (value == 1) if player_2

        Game.instance.player_id = value % 2 + 1
        Game.instance.opponent_id = value
      end

      log(:analyzer, "player_1 is player : #{player_1.is_player}") if player_1
      log(:analyzer, "player_2 is player : #{player_2.is_player}") if player_2
    end

    controller = Game.instance.entities[id].tag(GameTag::CONTROLLER).to_i
    card_id = Game.instance.entities[id].card_id

    if tag == GameTag::ZONE
      if (value == Zone::HAND || (value == Zone::PLAY) && Game.instance.is_mulligan_done) && Game.instance.wait_controller.nil?
        unless Game.instance.is_mulligan_done
          prev_zone = Zone::DECK
        end
        if controller == 0
          Game.instance.entities[id].set_tag(GameTag::ZONE, prev_zone)
          Game.instance.wait_controller = { tag: tag, id: id, value: value }
          return
        end
      end

      case prev_zone
        when Zone::DECK

          case value
            when Zone::HAND
              if controller == Game.instance.player_id
                Game.instance.player_draw(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id

                unless card_id.nil_or_empty?
                  Game.instance.entities[id].card_id = ''
                end

                Game.instance.opponent_draw(Game.instance.turn_number)
              end

            when Zone::REMOVEDFROMGAME, Zone::SETASIDE
              if controller == Game.instance.player_id
                if Game.instance.joust_reveals > 0
                  Game.instance.joust_reveals -= 1
                  return
                end
                Game.instance.player_remove_from_deck(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                if Game.instance.joust_reveals > 0
                  Game.instance.joust_reveals -= 1
                  return
                end
                Game.instance.opponent_remove_from_deck(card_id, Game.instance.turn_number)
              end

            when Zone::GRAVEYARD
              if controller == Game.instance.player_id
                Game.instance.player_deck_discard(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_deck_discard(card_id, Game.instance.turn_number)
              end

            when Zone::PLAY
              if controller == Game.instance.player_id
                Game.instance.player_deck_to_play(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_deck_to_play(card_id, Game.instance.turn_number)
              end

            when Zone::SECRET
              if controller == Game.instance.player_id
                Game.instance.player_secret_played(card_id, Game.instance.turn_number, true)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_secret_played(card_id, -1, Game.instance.turn_number, true, id)
              end
          end

        when Zone::HAND

          case value
            when Zone::PLAY
              if controller == Game.instance.player_id
                Game.instance.player_play(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_play(card_id, Game.instance.entities[id].tag(GameTag::ZONE_POSITION), Game.instance.turn_number)
              end

            when Zone::REMOVEDFROMGAME, Zone::GRAVEYARD
              if controller == Game.instance.player_id
                Game.instance.player_hand_discard(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_hand_discard(card_id, Game.instance.entities[id].tag(GameTag::ZONE_POSITION), Game.instance.turn_number)
              end

            when Zone::SECRET
              if controller == Game.instance.player_id
                Game.instance.player_secret_played(card_id, Game.instance.turn_number, false)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_secret_played(card_id, Game.instance.entities[id].tag(GameTag::ZONE_POSITION), Game.instance.turn_number, false, id)
              end

            when Zone::DECK
              if controller == Game.instance.player_id
                Game.instance.player_mulligan(card_id)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_mulligan(Game.instance.entities[id].tag(GameTag::ZONE_POSITION))
              end
          end

        when Zone::PLAY

          case value
            when Zone::HAND
              if controller == Game.instance.player_id
                Game.instance.player_back_to_hand(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_play_to_hand(card_id, Game.instance.turn_number, id)
              end

            when Zone::DECK
              if controller == Game.instance.player_id
                Game.instance.player_play_to_deck(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_play_to_deck(card_id, Game.instance.turn_number)
              end

            when Zone::GRAVEYARD
              if Game.instance.entities[id].has_tag? GameTag::HEALTH
                if controller == Game.instance.player_id
                elsif controller == Game.instance.opponent_id
                end
              end
          end

        when Zone::SECRET
          case value
            when Zone::SECRET, Zone::GRAVEYARD
              if controller == Game.instance.player_id
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_secret_trigger(card_id, Game.instance.turn_number, id)
              end
          end

        when Zone::GRAVEYARD, Zone::SETASIDE, Zone::CREATED, Zone::INVALID, Zone::REMOVEDFROMGAME
          case value
            when Zone::PLAY
              if controller == Game.instance.player_id
              elsif controller == Game.instance.opponent_id
              end

            when Zone::DECK
              if controller == Game.instance.player_id
                return if Game.instance.joust_reveals > 0
                Game.instance.player_get_to_deck(card_id, Game.instance.turn_number)
              elsif controller == Game.instance.opponent_id
                return if Game.instance.joust_reveals > 0
                Game.instance.opponent_get_to_deck(card_id, Game.instance.turn_number)
              end

            when Zone::HAND
              if controller == Game.instance.player_id
                Game.instance.player_get(card_id, Game.instance.turn_number)
                #if Game.instance.entities[id].has_tag?(GameTag::LINKEDCARD)
                #  linked_card = Game.instance.entities[id].tag(GameTag::LINKEDCARD)
                #  to_remove = Game.instance.entities[linked_card]
                #  if to_remove && to_remove.is_in_zone?(Zone::HAND)
                #    Game.instance.player_hand_discard(to_remove.card_id, Game.instance.turn_number)
                #  end
                #end
              elsif controller == Game.instance.opponent_id
                Game.instance.opponent_get(Game.instance.turn_number, id)
              end
          end
      end

    elsif tag == GameTag::PLAYSTATE
      if value == PlayState::CONCEDED
        Game.instance.concede
      end
      if Game.instance.game_started
        if Game.instance.entities[id].is_player
          if value == PlayState::WON
            Game.instance.game_started = false
            Game.instance.win
            Game.instance.game_end
          elsif value == PlayState::LOST
            Game.instance.game_started = false
            Game.instance.loss
            Game.instance.game_end
          elsif value == PlayState::TIED
            Game.instance.game_started = false
            Game.instance.tied
            Game.instance.game_end
          end
        end
      end
    elsif tag == GameTag::CURRENT_PLAYER && value == 1
      # be sure to "reset" cards from tracking
      player = Game.instance.entities[id].is_player ? :player : :opponent
      Game.instance.turn_start(player, Game.instance.turn_number)

      if player == :player
        @player_used_hero_power = false
      else
        @opponent_used_hero_power = false
      end

    elsif tag == GameTag::NUM_ATTACKS_THIS_TURN && value > 0
    elsif tag == GameTag::ZONE_POSITION
    elsif tag == GameTag::CARD_TARGET && value > 0
    elsif tag == GameTag::EQUIPPED_WEAPON && value == 0
    elsif tag == GameTag::EXHAUSTED && value > 0
    elsif tag == GameTag::CONTROLLER && Game.instance.entities[id].is_in_zone?(Zone::SECRET)
      if value == Game.instance.player_id
        Game.instance.opponent_secret_trigger(card_id, Game.instance.turn_number, id)
      end
    elsif tag == GameTag::FATIGUE
      if controller == Game.instance.player_id
        Game.instance.player_fatigue(value)
      elsif controller == Game.instance.opponent_id
        Game.instance.opponent_fatigue(value)
      end
    end

    if !Game.instance.wait_controller.nil? && !recurse
      tag_change(Game.instance.wait_controller[:tag], Game.instance.wait_controller[:id], Game.instance.wait_controller[:value], true)
      Game.instance.wait_controller = nil
    end

  end

  # parse an entity
  def parse_entity(entity)
    id = name = zone = zone_pos = card_id = player = type = nil

    id = /id=(\d+)/.match(entity)[1].to_i if entity =~ /id=(\d+)/
    name = /name=(\w+)/.match(entity)[1] if entity =~ /name=(\w+)/
    zone = /zone=(\w+)/.match(entity)[1] if entity =~ /zone=(\w+)/
    zone_pos = /zonePos=(\d+)/.match(entity)[1] if entity =~ /zonePos=(\d+)/
    card_id = /cardId=(\w+)/.match(entity)[1] if entity =~ /cardId=(\w+)/
    player = /player=(\d+)/.match(entity)[1] if entity =~ /player=(\d+)/
    type = /type=(\w+)/.match(entity)[1] if entity =~ /type=(\w+)/

    return id, name, zone, zone_pos, card_id, player, type
  end

  # check if the entity is a raw entity
  def is_entity?(entity)
    id, name, zone, zone_pos, card_id, player, type = parse_entity(entity)
    !id.nil? || !name.nil? || !zone.nil? || !zone_pos.nil? || !card_id.nil? || !player.nil? || !type.nil?
  end

  def parse_tag(tag, raw_value)
    if tag == GameTag::ZONE
      Zone.parse(raw_value)
    elsif tag == GameTag::MULLIGAN_STATE
      Mulligan.parse(raw_value)
    elsif tag == GameTag::PLAYSTATE
      PlayState.parse(raw_value)
    elsif tag == GameTag::CARDTYPE
      CardType.parse(raw_value)
    elsif raw_value.is_a?(String) && raw_value.is_i?
      raw_value.to_i
    else
      0
    end
  end
end
