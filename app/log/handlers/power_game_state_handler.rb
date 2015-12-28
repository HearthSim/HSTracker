class PowerGameStateHandler

  def self.handle(line)
    @tmp_entities ||= []
    @tag_change_handler ||= TagChangeHandler.new

    # game start
      if line =~ /CREATE_GAME/
        Game.instance.game_start

        # current game
      elsif (match = /GameEntity EntityID=(\d+)/.match(line))
        Game.instance.game_start
        id = match[1].to_i

        unless Game.instance.entities.has_key? id
          Game.instance.entities[id] = Entity.new(id)
        end
        @current_entity = id

        # players
      elsif (match = /Player EntityID=(\d+) PlayerID=(\d+) GameAccountId=(.+)/.match(line))
        entity = match[1].to_i

        unless Game.instance.entities.has_key? entity
          Game.instance.entities[entity] = Entity.new(entity)
        end
        @current_entity = entity

      elsif (match = /TAG_CHANGE Entity=([\w\s]+\w) tag=PLAYER_ID value=(\d)/.match(line))
        name = match[1]
        player = match[2].to_i

        entity = Game.instance.entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == player }.values.first
        return if entity.nil?

        if entity.is_player
          Game.instance.player_name(name)
        else
          Game.instance.opponent_name(name)
        end

      elsif (match = /TAG_CHANGE Entity=(.+) tag=(\w+) value=(\w+)/.match(line))
        raw_entity = match[1].sub(/UNKNOWN ENTITY /, '')
        tag = match[2]
        value = match[3]

        if raw_entity =~ /^\[/ && @tag_change_handler.is_entity?(raw_entity)
          id, _, _, _, _, _, _ = @tag_change_handler.parse_entity(raw_entity)
          @tag_change_handler.tag_change(tag, id, value)
        elsif raw_entity.is_i?
          @tag_change_handler.tag_change(tag, raw_entity.to_i, value)
        else
          s_entity = Game.instance.entities.select { |_, val| val.name == raw_entity }.values.first
          if s_entity.nil?

            tmp_entity = Game.instance.entities.select { |_, val| val.name == 'UNKNOWN HUMAN PLAYER' }.values.first
            unless tmp_entity.nil? or tmp_entity.is_a?(Array)
              tmp_entity.name = raw_entity
            end

            if tmp_entity.nil?
              tmp_entity = @tmp_entities.select { |val| val.name == raw_entity }.first
            end

            if tmp_entity.nil?
              tmp_entity = Entity.new(@tmp_entities.size + 1)
              tmp_entity.name = raw_entity
              @tmp_entities << tmp_entity
            end

            tag = GameTag.parse(tag)
            value = @tag_change_handler.parse_tag(tag, value)
            tmp_entity.set_tag(tag, value)
            if tmp_entity.has_tag?(GameTag::ENTITY_ID)
              id = tmp_entity.tag(GameTag::ENTITY_ID).to_i

              if Game.instance.entities.has_key?(id)
                Game.instance.entities[id].name = tmp_entity.name
                tmp_entity.tags.each do |key, val|
                  Game.instance.entities[id].set_tag(key, val)
                end
                @tmp_entities.delete(tmp_entity)
              end
            end
          else
            @tag_change_handler.tag_change(tag, s_entity.id, value)
          end
        end

      elsif (match = /FULL_ENTITY - Creating ID=(\d+) CardID=(\w*)/.match(line))
        id = match[1].to_i
        card_id = match[2]

        unless Game.instance.entities.has_key? id
          entity = Entity.new(id)
          entity.card_id = card_id
          Game.instance.entities[id] = entity
        end
        @current_entity = id
        @tag_change_handler.current_entity_has_card_id = !(card_id.nil? || card_id.empty?)

      elsif (match = /SHOW_ENTITY - Updating Entity=(.+) CardID=(\w*)/.match(line))
        entity = match[1]
        card_id = match[2]

        entity_id = -1
        if entity =~ /^\[/ && @tag_change_handler.is_entity?(entity)
          entity_id, _, _, _, _, _, _ = @tag_change_handler.parse_entity(entity)
        elsif entity.is_i?
          entity_id = entity.to_i
        end

        unless entity_id.nil? || entity_id == -1
          unless Game.instance.entities.has_key? entity_id
            entity = Entity.new(entity_id)
            Game.instance.entities[entity_id] = entity
          end
          Game.instance.entities[entity_id].card_id = card_id
          @current_entity = entity_id
        end

        if Game.instance.joust_reveals > 0
          current_entity = Game.instance.entities[entity_id]
          if current_entity
            if current_entity.is_controlled_by?(Game.instance.opponent_id)
              Game.instance.opponent_joust(card_id, Game.instance.turn_number)
            elsif current_entity.is_controlled_by?(Game.instance.player_id)
              Game.instance.player_joust(card_id, Game.instance.turn_number)
            end
          end
        end

      elsif (match = /tag=(\w+) value=(\w+)/.match(line)) && !line.include?('HIDE_ENTITY')
        tag = match[1]
        value = match[2]

        @tag_change_handler.tag_change(tag, @current_entity, value)

      elsif line.include?('Begin Spectating') || line.include?('Start Spectator')
        Game.instance.game_mode = :spectator

      elsif line.include?('End Spectator')
        Game.instance.game_mode = :spectator
        Game.instance.game_end

      elsif (match = /.*ACTION_START.*id=(\w*).*cardId=(\w*).*BlockType=POWER.*Target=(.+)/i.match(line))
        id = match[1]
        local_id = match[2]
        target = match[3]

        player = Game.instance.entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == Game.instance.player_id }.values.first
        opponent = Game.instance.entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == Game.instance.opponent_id }.values.first

        if local_id.nil? || local_id.empty? && id
          entity = Game.instance.entities[id.to_i]
          local_id = entity.card_id
        end

        if local_id == 'BRM_007' # Gang Up
          card_id = nil
          if target =~ /^\[/ && @tag_change_handler.is_entity?(target)
            if (card_id_match = /cardId=(\w+)/.match(target))
              card_id = card_id_match[1]
            end
          end

          if !player.nil? && player.tag(GameTag::CURRENT_PLAYER).to_i == 1
            if card_id
              (0...3).each do |_|
                Game.instance.player_get_to_deck(card_id, Game.instance.turn_number)
              end
            end
          else
            (0...3).each do |_|
              Game.instance.opponent_get_to_deck(card_id, Game.instance.turn_number)
            end
          end

        elsif local_id == 'GVG_056' # Iron Juggernaut

          if !player.nil? && player.tag(GameTag::CURRENT_PLAYER).to_i == 1
            Game.instance.opponent_get_to_deck('GVG_056t', Game.instance.turn_number)
          else
            Game.instance.player_get_to_deck('GVG_056t', Game.instance.turn_number)
          end

        elsif (player && player.tag(GameTag::CURRENT_PLAYER).to_i == 1 && !@tag_change_handler.player_used_hero_power) || (opponent && opponent.tag(GameTag::CURRENT_PLAYER).to_i == 1 && !@tag_change_handler.opponent_used_hero_power)
          card = Card.by_id(local_id)
          if card && card.card_type == 'hero power'
            if player && player.tag(GameTag::CURRENT_PLAYER).to_i == 1
              @tag_change_handler.player_used_hero_power = true
              log(:analyzer, 'player use hero power')
            elsif opponent
              log(:analyzer, 'opponent use hero power')
              @tag_change_handler.opponent_used_hero_power = true
            end
          end
        end

      elsif line.include?('BlockType=JOUST')
        Game.instance.joust_reveals = 2
      end
  end
end
