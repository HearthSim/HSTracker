class LogObserver

  Log = Motion::Log

  def initialize
    super.tap do
      @last_read_position = 0

      # force initialization of data
      reset_data
    end
  end

  def start
    @should_run = true

    path = Hearthstone.log_path

    # if we are in full debug mode, we skip this
    unless Hearthstone::KDebugFromFile
      if path.file_exists?
        # if the file exists, we start reading at from the last started game
        path = Hearthstone.log_path

        file_handle = NSFileHandle.fileHandleForReadingAtPath(path)
        if file_handle.nil?
          NSAlert.alert('Error',
                        informative: "HSTracker can't read log file. Please restart HSTracker and Hearthstone to fix this issue",
                        style: NSCriticalAlertStyle
          )
          return
        end
        @last_read_position = find_last_game_start(file_handle)
      end
    end
    changes_in_file
  end

  def restart_last_game
    stop
    start
  end

  def debug(text)
    lines = text.split "\n"
    if lines.count > 0
      lines.each do |line|
        analyze(line)
      end
    end
  end

  def stop
    @should_run = false
  end

  def reset_data
    @game_started = false
    @coin_set = false
    @current_turn = -1
    @entities = {}
    @tmp_entities = []

    @spectating = true

    @player_id = nil
    @opponent_id = nil
  end

  def detect_mode(timeout_sec, &block)
    Log.verbose 'waiting for mode'
    Dispatch::Queue.concurrent.async do
      @awaiting_ranked_detection = true
      @waiting_for_first_asset_unload = true
      @found_ranked = false
      @last_asset_unload = NSDate.new.timeIntervalSince1970

      timeout = timeout_sec.seconds.after(NSDate.now).timeIntervalSince1970
      while @waiting_for_first_asset_unload || (NSDate.now.timeIntervalSince1970 - @last_asset_unload) < timeout
        NSThread.sleepForTimeInterval(0.1)
        break if @found_ranked
      end

      Dispatch::Queue.main.async do
        block.call(@found_ranked) if block
      end
    end
  end

  private
  def file_size(path)
    File.stat(path).size
  end

  # check each 0.5 sec if there are some modification in the log file
  def changes_in_file
    path = Hearthstone.log_path

    file_handle = NSFileHandle.fileHandleForReadingAtPath(path)
    if file_handle.nil?
      NSAlert.alert(:error._,
                    informative: :hstracker_error_log._,
                    style: NSCriticalAlertStyle
      )
      return
    end
    file_handle.seekToFileOffset(@last_read_position)

    Dispatch::Queue.concurrent.async do
      data = file_handle.readDataToEndOfFile
      lines_str = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      size = @last_read_position
      @last_read_position = file_size(path)

      if @last_read_position > size

        lines = lines_str.split "\n"
        Dispatch::Queue.main.async do
          if lines.count > 0
            lines.each do |line|
              analyze(line)
            end
          end
        end
      end

      Dispatch::Queue.main.after(0.5) do
        if @should_run
          changes_in_file
        end
      end
    end
  end

  def find_last_game_start(file_handle)
    offset = 0
    temp_offset = 0
    found_spectator_start = false

    file_handle.seekToFileOffset(0)
    data = file_handle.readDataToEndOfFile

    lines_str = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
    lines = lines_str.split "\n"
    lines.each do |line|
      if line.include?('Begin Spectating') || line.include?('Start Spectator')
        offset = temp_offset
        found_spectator_start = true
      elsif line.include?('End Spectator')
        offset = temp_offset
      elsif line.include?('CREATE_GAME') && line.include?('GameState.')
        if found_spectator_start
          found_spectator_start = false
          next
        end
        offset = temp_offset
        next
      end

      temp_offset += line.length + 1
      if line =~ /^\[Bob\] legend rank/
        if found_spectator_start
          found_spectator_start = false
          next
        end
        offset = temp_offset
      end
    end

    offset
  end

  ## analyze

  def entity_with_value(name, value)
    entity = nil
    @entities.each do |key, values|
      if values[name] && values[name] == value
        entity = key
      end
    end
    entity
  end

  def analyze(line)
    return if line.strip.size.zero?
    return if line =~ /^\(Filename/
    #if line =~ /CREATE_GAME/
    #puts "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
    #end
    #puts line
    #puts " "
    #return

    ## [POWER]
    if line =~ /^\[Power\] GameState\./
      # game start
      if line =~ /CREATE_GAME/
        start_game

        # current game
      elsif (match = /GameEntity EntityID=(\d+)/.match(line))
        start_game
        id = match[1].to_i

        unless @entities.has_key? id
          @entities[id] = Entity.new(id)
        end
        @current_entity = id

        # players
      elsif (match = /Player EntityID=(\d+) PlayerID=(\d+) GameAccountId=(.+)/.match(line))
        entity = match[1].to_i

        unless @entities.has_key? entity
          @entities[entity] = Entity.new(entity)
        end
        @current_entity = entity

      elsif (match = /TAG_CHANGE Entity=(\w+) tag=PLAYER_ID value=(\d)/.match(line))
        name = match[1]
        player = match[2].to_i

        entity = @entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == player }.values.first
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

        if raw_entity =~ /^\[/ && is_entity?(raw_entity)
          id, _, _, _, _, _, _ = parse_entity(raw_entity)
          tag_change(tag, id, value)
        elsif raw_entity.is_i?
          tag_change(tag, raw_entity.to_i, value)
        else
          s_entity = @entities.select { |_, val| val.name == raw_entity }.values.first
          if s_entity.nil?
            tmp_entity = @tmp_entities.select { |val| val.name == raw_entity }.first

            if tmp_entity.nil?
              tmp_entity = Entity.new(@tmp_entities.size + 1)
              tmp_entity.name = raw_entity
              @tmp_entities << tmp_entity
            end

            tag = GameTag.parse(tag)
            value = parse_tag(tag, value)
            tmp_entity.set_tag(tag, value)
            if tmp_entity.has_tag?(GameTag::ENTITY_ID)
              id = tmp_entity.tag(GameTag::ENTITY_ID).to_i

              if @entities.has_key?(id)
                @entities[id].name = tmp_entity.name
                tmp_entity.tags.each do |key, val|
                  @entities[id].set_tag(key, val)
                end
                @tmp_entities.delete(tmp_entity)
              end
            end
          else
            tag_change(tag, s_entity.id, value)
          end
        end

      elsif (match = /FULL_ENTITY - Creating ID=(\d+) CardID=(\w*)/.match(line))
        id = match[1].to_i
        card_id = match[2]

        unless @entities.has_key? id
          entity = Entity.new(id)
          entity.card_id = card_id
          @entities[id] = entity
        end
        @current_entity = id
        @current_entity_has_card_id = !(card_id.nil? || card_id.empty?)

      elsif (match = /SHOW_ENTITY - Updating Entity=(.+) CardID=(\w*)/.match(line))
        entity = match[1]
        card_id = match[2]

        entity_id = -1
        if entity =~ /^\[/ && is_entity?(entity)
          entity_id, _, _, _, _, _, _ = parse_entity(entity)
        elsif entity.is_i?
          entity_id = entity.to_i
        end

        unless entity_id.nil? || entity_id == -1
          unless @entities.has_key? entity_id
            entity = Entity.new(entity_id)
            @entities[entity_id] = entity
          end
          @entities[entity_id].card_id = card_id
          @current_entity = entity_id
        end

      elsif (match = /tag=(\w+) value=(\w+)/.match(line)) && !line.include?('HIDE_ENTITY')
        tag = match[1]
        value = match[2]

        tag_change(tag, @current_entity, value)

      elsif line.include?('Begin Spectating') || line.include?('Start Spectator')
        @game_mode = :spectator
        @spectating = true

      elsif line.include?('End Spectator')
        @game_mode = :spectator
        @spectating = true
        #game_end

      elsif (match = /.*ACTION_START.*id=(\w*).*cardId=(\w*).*BlockType=POWER.*Target=(.+)/i.match(line))
        id = match[1]
        local_id = match[2]
        target = match[3]

        player = @entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == @player_id }.values.first
        opponent = @entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == @opponent_id }.values.first

        if local_id.nil? || local_id.empty? && id
          entity = @entities[id.to_i]
          local_id = entity.card_id
        end

        if local_id == 'BRM_007' # Gang Up
          card_id = nil
          if target =~ /^\[/ && is_entity?(target)
            if (card_id_match = /cardId=(\w+)/.match(target))
              card_id = card_id_match[1]
            end
          end

          if !player.nil? && player.tag(GameTag::CURRENT_PLAYER).to_i == 1
            if card_id
              (0...3).each do |_|
                Game.instance.player_get_to_deck(card_id, turn_number)
              end
            end
          else
            (0...3).each do |_|
              Game.instance.opponent_get_to_deck(card_id, turn_number)
            end
          end

        elsif local_id == 'GVG_056' # Iron Juggernaut

          if !player.nil? && player.tag(GameTag::CURRENT_PLAYER).to_i == 1
            Game.instance.opponent_get_to_deck('GVG_056t', turn_number)
          else
            Game.instance.player_get_to_deck('GVG_056t', turn_number)
          end

        elsif (player && player.tag(GameTag::CURRENT_PLAYER).to_i == 1 && !@player_used_hero_power) || (opponent && opponent.tag(GameTag::CURRENT_PLAYER).to_i == 1 && !@opponent_used_hero_power)
          card = Card.by_id(local_id)
          if card && card.card_type == 'Hero Power'
            if player && player.tag(GameTag::CURRENT_PLAYER).to_i == 1
              @player_used_hero_power = true
              Log.verbose 'player use hero power'
            elsif opponent
              Log.verbose 'opponent use hero power'
              @opponent_used_hero_power = true
            end
          end
        end
      end

    elsif line =~ /^\[Asset\]/
      if @awaiting_ranked_detection
        @last_asset_unload = NSDate.new.timeIntervalSince1970
        @awaiting_ranked_detection = false
      end

      if (match = /Medal_Ranked_(\d+)/.match(line))
        rank = match[1].to_i
        Game.instance.player_rank(rank)

      elsif line.include? 'rank_window'
        @found_ranked = true
        @game_mode = :ranked
        Game.instance.game_mode(@game_mode)

      elsif (match = /unloading name=(\w+_\w+) family=CardPrefab persistent=False/.match(line))
        card_id = match[1]
        #if @game_mode == :arena
        #  Log.verbose "possible arena card draft : #{card_id} ?"
        #else
        #  Log.verbose "possible constructed card draft : #{card_id} ?"
        #end

      elsif line =~ /unloading name=Tavern_Brawl/
        @game_mode = :brawl
        Game.instance.game_mode(@game_mode)
      end

    elsif line.start_with?('[Bob] ---RegisterScreenPractice---')
      Game.instance.game_mode(:practice)

    elsif line.start_with?('[Bob] ---RegisterScreenTourneys---')
      Game.instance.game_mode(:casual)

    elsif line.start_with?('[Bob] ---RegisterScreenForge---')
      Game.instance.game_mode(:arena)

    elsif line.start_with?('[Bob] ---RegisterScreenFriendly---')
      Game.instance.game_mode(:friendly)

    elsif line =~ /^\[Rachelle\]/

      if (match = /(\d)\/3 wins towards 10 gold/.match(line))
        victories = match[1].to_i
        Log.debug "#{victories} / 3 -> 10 gold"
      end

      if (match = /.*somehow the card def for (\w+_\w+) was already in the cache\.\.\./.match(line))
        card_id = match[1]
        #if @game_mode == :arena
        #  Log.verbose "possible arena card draft : #{card_id} ?"
        #else
        #  Log.verbose "possible constructed card draft : #{card_id} ?"
        #end

      end

    elsif line =~ /^\[Zone\]/

      if (match = /ProcessChanges.*TRANSITIONING card \[name=(.*).*zone=PLAY.*cardId=(.*).*player=(\d)\] to (.*) \(Hero\)/i.match(line))

        card_id = match[2].strip
        to = match[4]

        if to =~ /FRIENDLY PLAY/
          Game.instance.player_hero(card_id)
        else
          Game.instance.opponent_hero(card_id)
        end
      end
    end
  end

  def start_game
    return if @game_started

    reset_data
    @game_started = true

    Game.instance.game_start
  end

  def tag_change(raw_tag, id, raw_value, recurse=false)

    unless @entities.has_key? id
      @entities[id] = Entity.new(id)
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

    prev_zone = @entities[id].tag(GameTag::ZONE)
    @entities[id].set_tag(tag, value)

    if tag == GameTag::CONTROLLER && !@wait_controller.nil? && @player_id.nil?
      player_1 = @entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == 1 }.values.first
      player_2 = @entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && val.tag(GameTag::PLAYER_ID).to_i == 2 }.values.first

      if @current_entity_has_card_id
        player_1.is_player = (value == 1) if player_1
        player_2.is_player = (value != 1) if player_2

        @player_id = value
        @opponent_id = value == 1 ? 2 : 1

      else
        player_1.is_player = (value != 1) if player_1
        player_2.is_player = (value == 1) if player_2

        @player_id = value == 1 ? 2 : 1
        @opponent_id = value
      end

      Log.verbose "player_1 is player : #{player_1.is_player}" if player_1
      Log.verbose "player_2 is player : #{player_2.is_player}" if player_2
    end

    controller = @entities[id].tag(GameTag::CONTROLLER).to_i
    card_id = @entities[id].card_id

    if tag == GameTag::ZONE
      if (value == Zone::HAND || (value == Zone::PLAY) && is_mulligan_done) && @wait_controller.nil?
        unless is_mulligan_done
          prev_zone = Zone::DECK
        end
        if controller == 0
          @entities[id].set_tag(GameTag::ZONE, prev_zone)
          @wait_controller = { tag: tag, id: id, value: value }
          return
        end
      end

      case prev_zone
        when Zone::DECK

          case value
            when Zone::HAND
              if controller == @player_id
                Game.instance.player_draw(card_id, turn_number)
              elsif controller == @opponent_id
                Game.instance.opponent_draw(turn_number)
              end

            when Zone::REMOVEDFROMGAME, Zone::GRAVEYARD, Zone::SETASIDE, Zone::PLAY
              if controller == @player_id
                Game.instance.player_deck_discard(card_id, turn_number)
              elsif controller == @opponent_id
                Game.instance.opponent_deck_discard(card_id, turn_number)
              end

            when Zone::SECRET
              if controller == @player_id
                Game.instance.player_secret_played(card_id, turn_number, true)
              elsif controller == @opponent_id
                Game.instance.opponent_secret_played(card_id, -1, turn_number, true, id)
              end
          end

        when Zone::HAND

          case value
            when Zone::PLAY
              if controller == @player_id
                Game.instance.player_play(card_id, turn_number)
              elsif controller == @opponent_id
                Game.instance.opponent_play(card_id, @entities[id].tag(GameTag::ZONE_POSITION), turn_number)
              end

            when Zone::REMOVEDFROMGAME, Zone::GRAVEYARD
              if controller == @player_id
                Game.instance.player_hand_discard(card_id, turn_number)
              elsif controller == @opponent_id
                Game.instance.opponent_hand_discard(card_id, @entities[id].tag(GameTag::ZONE_POSITION), turn_number)
              end

            when Zone::SECRET
              if controller == @player_id
                Game.instance.player_secret_played(card_id, turn_number, false)
              elsif controller == @opponent_id
                Game.instance.opponent_secret_played(card_id, @entities[id].tag(GameTag::ZONE_POSITION), turn_number, false, id)
              end

            when Zone::DECK
              if controller == @player_id
                Game.instance.player_mulligan(card_id)
              elsif controller == @opponent_id
                Game.instance.opponent_mulligan(@entities[id].tag(GameTag::ZONE_POSITION))
              end
          end

        when Zone::PLAY

          case value
            when Zone::HAND
              if controller == @player_id
                Game.instance.player_back_to_hand(card_id, turn_number)
              elsif controller == @opponent_id
                Game.instance.opponent_play_to_hand(card_id, turn_number, id)
              end

            when Zone::DECK
              if controller == @player_id
                Game.instance.player_play_to_deck(card_id, turn_number)
              elsif controller == @opponent_id
                Game.instance.opponent_play_to_deck(card_id, turn_number)
              end

            when Zone::GRAVEYARD
              if @entities[id].has_tag? GameTag::HEALTH
                if controller == @player_id
                elsif controller == @opponent_id
                end
              end
          end

        when Zone::SECRET
          case value
            when Zone::SECRET, Zone::GRAVEYARD
              if controller == @player_id
              elsif controller == @opponent_id
                Game.instance.opponent_secret_trigger(card_id, turn_number, id)
              end
          end

        when Zone::GRAVEYARD, Zone::SETASIDE, Zone::CREATED, Zone::INVALID, Zone::REMOVEDFROMGAME
          case value
            when Zone::PLAY
              if controller == @player_id
              elsif controller == @opponent_id
              end

            when Zone::HAND
              if controller == @player_id
                Game.instance.player_get(card_id, turn_number)
                if @entities[id].has_tag?(GameTag::LINKEDCARD)
                  linked_card = @entities[id].tag(GameTag::LINKEDCARD)
                  to_remove = @entities[linked_card]
                  if to_remove && to_remove.is_in_zone?(Zone::HAND)
                    Game.instance.player_hand_discard(to_remove.card_id, turn_number)
                  end

                end
              elsif controller == @opponent_id
                Game.instance.opponent_get(turn_number, id)
              end
          end
      end

    elsif tag == GameTag::PLAYSTATE
      if value == PlayState::QUIT
        Game.instance.concede
      end
      if @game_started
        if @entities[id].is_player
          if value == PlayState::WON
            @game_started = false
            Game.instance.win
            Game.instance.game_end
          elsif value == PlayState::LOST
            @game_started = false
            Game.instance.loss
            Game.instance.game_end
          elsif value == PlayState::TIED
            @game_started = false
            Game.instance.tied
            Game.instance.game_end
          end
        end
      end
    elsif tag == GameTag::CURRENT_PLAYER && value == 1
      # be sure to "reset" cards from tracking
      player = @entities[id].is_player ? :player : :opponent
      Game.instance.turn_start(player, turn_number)

      @player_used_hero_power = false
      @opponent_used_hero_power = false

    elsif tag == GameTag::NUM_ATTACKS_THIS_TURN && value > 0
    elsif tag == GameTag::ZONE_POSITION
    elsif tag == GameTag::CARD_TARGET && value > 0
    elsif tag == GameTag::EQUIPPED_WEAPON && value == 0
    elsif tag == GameTag::EXHAUSTED && value > 0
    elsif tag == GameTag::CONTROLLER && @entities[id].is_in_zone?(Zone::SECRET)
      if value == @player_id
        Game.instance.opponent_secret_trigger(card_id, turn_number, id)
      end
    elsif tag == GameTag::FATIGUE
      if controller == @player_id
        Game.instance.player_fatigue(value)
      elsif controller == @opponent_id
        Game.instance.opponent_fatigue(value)
      end
    end

    if !@wait_controller.nil? && !recurse
      tag_change(@wait_controller[:tag], @wait_controller[:id], @wait_controller[:value], true)
      @wait_controller = nil
    end

  end

  def turn_number
    return 0 unless is_mulligan_done

    if @current_turn == -1
      player = @entities.select { |_, val| val.has_tag?(GameTag::FIRST_PLAYER) }.values.first
      unless player.nil?
        @current_turn = player.tag(GameTag::CONTROLLER) == @player_id ? 0 : 1
      end
    end

    entity = @entities.values.first
    if entity
      return (entity.tag(GameTag::TURN).to_i + (@current_turn == -1 ? 0 : @current_turn)) / 2
    end

    0
  end

  def is_mulligan_done
    player = @entities.select { |_, val| val.is_player }.values.first
    opponent = @entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && !val.is_player }.values.first

    return false if player.nil? || opponent.nil?

    player.tag(GameTag::MULLIGAN_STATE) == Mulligan::DONE && opponent.tag(GameTag::MULLIGAN_STATE) == Mulligan::DONE
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
      value = Zone.parse(raw_value)
    elsif tag == GameTag::MULLIGAN_STATE
      value = Mulligan.parse(raw_value)
    elsif tag == GameTag::PLAYSTATE
      value = PlayState.parse(raw_value)
    elsif tag == GameTag::CARDTYPE
      value = CardType.parse(raw_value)
    elsif raw_value.is_a?(String) && raw_value.is_i?
      value = raw_value.to_i
    end
    value
  end

end
