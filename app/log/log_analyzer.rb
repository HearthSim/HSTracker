class LogAnalyzer

  Log = Motion::Log

  # blocks for card stuff
  def on_card(event, &block)
    @on_cards        ||= {}
    @on_cards[event] = block.respond_to?('weak!') ? block.weak! : block
  end

  # player names
  def on_player_name(&block)
    @on_player_name = block.respond_to?('weak!') ? block.weak! : block
  end

  # game status
  def on_game_start(&block)
    @on_game_start = block.respond_to?('weak!') ? block.weak! : block
  end

  def on_game_end(&block)
    @on_game_end = block.respond_to?('weak!') ? block.weak! : block
  end

  # game heroes
  def on_hero(&block)
    @on_hero = block.respond_to?('weak!') ? block.weak! : block
  end

  # coin
  def on_coin(&block)
    @on_coin = block.respond_to?('weak!') ? block.weak! : block
  end

  def entity(id, name, value)
    unless @entities[id]
      @entities[id] = {}
    end

    @entities[id][name] = value
  end

  def entity_with_value(name, value)
    entity = nil
    @entities.each do |key, values|
      if values[name] and values[name] == value
        entity = key
      end
    end
    entity
  end

  def analyze(line)
    return if line.strip.size.zero?
    return if /^\(Filename:/ =~ line

    match = /FULL_ENTITY - Creating ID=(\d+) CardID=(\w*)/.match(line)
    if match
      id      = match[1]
      card_id = match[2]

      entity(id, :card_id, card_id)
    end

    # cards play
    match = /ProcessChanges.*\[.*id=(\d+).*cardId=(\w+|).*\].*zone from (.*) -> (.*)/i.match(line)
    if match
      id      = match[1]
      card_id = match[2]
      from    = match[3]
      to      = match[4]

      card = Card.by_id(card_id)
      if card
        card = card.name
      end

      if from =~ /(FRIENDLY DECK|)/ and to =~ /FRIENDLY HAND/
        # player or opponent draw
        # ignore if opponent as we have no clue which card is it
        Log.debug "draw #{card_id} (#{card})"
        @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]

      elsif from =~ /HAND/ and to =~ /DECK/
        # player or opponent mulligan
        # ignore if opponent as we have no clue which card is it
        if to =~ /FRIENDLY/
          Log.debug "mulligan #{card_id} (#{card})"
          @on_cards[:return_deck_card].call(:player, card_id) if @on_cards[:return_deck_card]
        end

      elsif from =~ /HAND/ and to =~ /GRAVEYARD/
        # player or opponent discard a card
        if to =~ /FRIENDLY/
          Log.debug "player discard #{card_id} (#{card})"
          @on_cards[:discard_card].call(:player, card_id) if @on_cards[:discard_card]
        elsif to =~ /OPPOSING/
          Log.debug "opponent discard #{card_id} (#{card})"
          @on_cards[:discard_card].call(:opponent, card_id) if @on_cards[:discard_card]
        end

      elsif from =~ /FRIENDLY PLAY/ and to =~ /FRIENDLY PLAY/
        Log.debug "card returned from '#{from}' to '#{to}' -> #{card_id} (#{card})"

      elsif from =~ /FRIENDLY HAND/
        # player played a card
        Log.debug "player play #{card_id} (#{card})"
        @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]

      elsif from =~ /OPPOSING HAND/
        # opponent played a card

        if card_id != '' # card_id is '' -> opponent played a secret
          Log.debug "opponent play #{card_id} (#{card})"
          @on_cards[:play_card].call(:opponent, card_id) if @on_cards[:play_card]
        end

      elsif from =~ /OPPOSING SECRET/ and to =~ /OPPOSING GRAVEYARD/
        # opponent secret is revelead
        Log.debug "opponent secret is revelead #{card_id} (#{card})"
        @on_cards[:play_card].call(:opponent, card_id) if @on_cards[:play_card]

      elsif from =~ /DECK/ and to =~ /FRIENDLY SECRET/
        # player secret arrived (mad scientist, stuff like this)
        # fake draw and fake play
        Log.debug "a wide player secret #{card_id} appear (#{card})"
        @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]
        @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]

      elsif from =~ /FRIENDLY DECK/ and to =~ /FRIENDLY GRAVEYARD/
        # my hand is too full ! card burn !
        # considered it as drawned and played
        Log.debug "player burn card #{card_id} (#{card})"
        @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]
        @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]

      elsif from =~ /FRIENDLY DECK/ and to == ''
        # display card from tracking ?
        Log.debug "player show card #{card_id} (#{card})"
        @tracking_cards << card_id

      elsif from == '' and to =~ /FRIENDLY HAND/
        # is this the card choosen from tracking ?
        if @tracking_cards and @tracking_cards.size == 3

          # consider player have played the discard cards
          @tracking_cards.each do |tracking_card|

            # draw this card
            if tracking_card == card_id
              Log.debug "draw from tracking #{card_id} (#{card})"
              @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]
            else
              Log.debug "discard from tracking -> consider played #{tracking_card} (#{Card.by_id(tracking_card).name})"
              @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]
            end
          end

          @tracking_cards = []
        end

      else
        #Log.verbose "*** from '#{from}' to '#{to}' -> #{card_id} (#{card})"
      end

    end

    # Turn Info
    if line =~ /change=powerTask.*tag=NEXT_STEP value=MAIN_ACTION/ and @game_started
      @current_turn   += 1

      # be sure to "reset" cards from tracking
      @tracking_cards = []

      Log.debug 'next turn'
    end

    # coin
    match = /ProcessChanges.*zonePos=5.*zone from  -> (.*)/.match(line)
    if match
      to = match[1]

      if to =~ /FRIENDLY HAND/
        Log.debug 'coin for player'

        @players[:player][:coin]   = true
        @players[:opponent][:coin] = false

        @on_coin.call(:player) if @on_coin
      elsif to =~ /OPPOSING HAND/
        Log.debug 'coin for opponent'

        @players[:player][:coin]   = false
        @players[:opponent][:coin] = true

        @on_coin.call(:opponent) if @on_coin
      end
    end

    # hero
    match = /ProcessChanges.*TRANSITIONING card \[name=(.*).*zone=PLAY.*cardId=(.*).*player=(\d)\] to (.*) \(Hero\)/i.match(line)
    if match

      start_game

      card_id = match[2].strip
      to      = match[4]

      if to =~ /FRIENDLY PLAY/
        @players[:player][:hero] = card_id
        @on_hero.call(:player, card_id) if @on_hero
      else
        @players[:opponent][:hero] = card_id
        @on_hero.call(:opponent, card_id) if @on_hero
      end
    end

    # game start
    if line =~ /CREATE_GAME/
      start_game
    end

    # game end
    match = /\[Asset\].*name=(victory|defeat)_screen_start/.match(line)
    if match
      status = match[1]

      case status.downcase
        when 'victory'
          Log.verbose 'victory_screen_start'
          end_game(:player)
        when 'defeat'
          Log.verbose 'defeat_screen_start'
          end_game(:opponent)
        else
      end
    end

    # get rank
    match = /\[Asset\].*Medal_Ranked_(\d+)/.match(line)
    if match
      rank = match[1].to_i
      Log.debug "You are rank #{rank}"
    end

    # gold tracking
    match = /(\d)\/3 wins towards 10 gold/.match(line)
    if match
      victories = match[1]
      Log.debug "#{victories} / 3 -> 10 gold"
    end

    # game mode
    match = /\[Bob\] ---(\w+)---/.match(line)
    if match
      _game_mode = match[1]

      case _game_mode
        when 'RegisterScreenPractice'
          @game_mode = :adventures
        when 'RegisterScreenTourneys'
          @game_mode = :casual
        when 'RegisterScreenForge'
          @game_mode = :arena
        when 'RegisterScreenFriendly'
          @game_mode = :friendly
        else
          Log.warn "unknown game mode #{_game_mode}"
      end

      Log.debug "Player in game mode #{@game_mode}"
    end

    if line =~ /name=rank_window/
      @game_mode = :ranked
      Log.debug "Player in game mode #{@game_mode}"
    end

    if line =~ /\[Power\].*Begin Spectating/
      @spectating = true
    end

    # players
    match = /Player EntityID=(\d+) PlayerID=(\d+) GameAccountId=(.+)/.match(line)
    if match
      entity    = match[1]
      player_id = match[2].to_i

      entity(entity, :player_id, player_id)
    end

    match = /TAG_CHANGE Entity=(\w+) tag=PLAYER_ID value=(\d)/.match(line)
    if match
      name  = match[1]
      value = match[2].to_i

      if @players[:player][:coin]
        player = (value == 1) ? :player : :opponent
      else
        player = (value == 1) ? :opponent : :player
      end

      Log.debug "#{player}'s name is #{name}"
      @players[player][:name] = name
      @on_player_name.call(player, name) if @on_player_name
    end

    match = /TAG_CHANGE Entity=(.+) tag=(\w+) value=(\w+)/.match(line)
    if match
      entity = match[1]
      tag    = match[2]
      value  = match[3]

      # game end
      if tag == 'PLAYSTATE'
        game_ended = false
        winner     = nil

        player = player(entity)

        case value

          # player concede
          when 'QUIT'
            game_ended = true
            winner     = :opponent
          when 'WON'
            game_ended = true
            winner     = player
          when 'LOST'
            game_ended = true
            winner     = (player == :opponent) ? :player : :opponent
          #when 'TIED'
          #game_ended = true
        end

        if game_ended and winner
          end_game(winner)
        end

      elsif tag == 'ZONE'
        #Log.debug "****** entity : #{entity}, tag : #{tag}, value : #{value}"

        # check players
      elsif tag == 'CONTROLLER'
        unless @players[:player][:id]
          player_1 = entity_with_value(:player_id, 1)
          player_2 = entity_with_value(:player_id, 2)

          value = value.to_i

          if player_1
            entity(player_1, :is_player, value == 1)
          end
          if player_2
            entity(player_2, :is_player, value != 1)
          end

          @players[:player][:id]   = value
          @players[:opponent][:id] = value == 1 ? 2 : 1
        end
      end

      if @game_mode == :arena
        match = /\[Rachelle\].*somehow the card def for (\w+_\w+) was already in the cache\.\.\./.match(line)
        if match
          card_id = match[1]
          Log.verbose "possible arena card draft : #{card_id} ?"
        end

        match = /\[Asset\].*unloading name=(\w+_\w+) family=CardPrefab persistent=False/.match(line)
        if match
          card_id = match[1]
          Log.verbose "possible arena card draft : #{card_id} ?"
        end
      end
    end

  end

  def player(name)
    return :player if @players[:player][:name] == name
    :opponent
  end

  def reset_data
    @current_turn   = 0
    @tracking_cards = []
    @entities       = {}

    @spectating = true

    @players = {
        :player   => {},
        :opponent => {}
    }
  end

  def start_game
    return if @game_started

    @game_started = true
    reset_data

    Log.debug '----- Game Started -----'
    @on_game_start.call if @on_game_start
  end

  def end_game(winner)
    return unless @game_started

    @game_started = false

    if winner == :player
      Log.debug 'You win \o/'
    else
      Log.debug 'You loose :('
    end

    Log.debug '----- Game End -----'
    @on_game_end.call(winner)
  end

end