class LogAnalyzer

  # blocks for card stuff
  def on_card(event, &block)
    @on_cards        ||= {}
    @on_cards[event] = block.respond_to?('weak!') ? block.weak! : block
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

  def analyze(line)
    return if line.strip.size.zero?
    return if /^\(Filename:/ =~ line

    puts line

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
        puts "draw #{card_id} (#{card})"
        @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]

      elsif from =~ /HAND/ and to =~ /DECK/
        # player or opponent mulligan
        # ignore if opponent as we have no clue which card is it
        if to =~ /FRIENDLY/
          puts "mulligan #{card_id} (#{card})"
          @on_cards[:return_deck_card].call(:player, card_id) if @on_cards[:return_deck_card]
        end

      elsif from =~ /HAND/ and to =~ /GRAVEYARD/
        # player or opponent discard a card
        if to =~ /FRIENDLY/
          puts "player discard #{card_id} (#{card})"
          @on_cards[:discard_card].call(:player, card_id) if @on_cards[:discard_card]
        elsif to =~ /OPPOSING/
          puts "opponent discard #{card_id} (#{card})"
          @on_cards[:discard_card].call(:opponent, card_id) if @on_cards[:discard_card]
        end

      elsif from =~ /FRIENDLY PLAY/ and to =~ /FRIENDLY PLAY/
        puts "card returned from '#{from}' to '#{to}' -> #{card_id} (#{card})"

      elsif from =~ /FRIENDLY HAND/
        # player played a card
        puts "player play #{card_id} (#{card})"
        @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]

      elsif from =~ /OPPOSING HAND/
        # opponent played a card
        puts "opponent play #{card_id} (#{card})"
        @on_cards[:play_card].call(:opponent, card_id) if @on_cards[:play_card]

      elsif from =~ /OPPOSING SECRET/ and to =~ /OPPOSING GRAVEYARD/
        # opponent secret is revelead
        puts "opponent secret is revelead #{card_id} (#{card})"
        @on_cards[:play_card].call(:opponent, card_id) if @on_cards[:play_card]

      elsif from =~ /DECK/ and to =~ /FRIENDLY SECRET/
        # player secret arrived (mad scientist, stuff like this)
        # fake draw and fake play
        puts "a wide player secret #{card_id} appear (#{card})"
        @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]
        @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]

      elsif from =~ /FRIENDLY DECK/ and to =~ /FRIENDLY GRAVEYARD/
        # my hand is too full ! card burn !
        # considered it as drawned and played
        puts "player burn card #{card_id} (#{card})"
        @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]
        @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]

      elsif from =~ /FRIENDLY DECK/ and to == ''
        # display card from tracking ?
        @tracking_cards ||= []
        puts "player show card #{card_id} (#{card})"
        @tracking_cards << card_id

      elsif from == '' and to =~ /FRIENDLY HAND/
        # is this the card choosen from tracking ?
        if @tracking_cards and @tracking_cards.size == 3

          # consider player have played the discard cards
          @tracking_cards.each do |tracking_card|

            # draw this card
            if tracking_card == card_id
              puts "draw from tracking #{card_id} (#{card})"
              @on_cards[:draw_card].call(:player, card_id) if @on_cards[:draw_card]
            else
              puts "discard from tracking -> consider played #{tracking_card} (#{Card.by_id(tracking_card).name})"
              @on_cards[:play_card].call(:player, card_id) if @on_cards[:play_card]
            end
          end

          @tracking_cards = []
        end

      else
        puts "from '#{from}' to '#{to}' -> #{card_id} (#{card})"
      end

    end

    # Turn Info
    if line =~ /change=powerTask.*tag=NEXT_STEP value=MAIN_ACTION/
      @current_turn   += 1

      # be sure to "reset" cards from tracking
      @tracking_cards = [] if @tracking_cards

      puts 'next turn'
    end

    # coin
    match = /ProcessChanges.*zonePos=5.*zone from  -> (.*)/.match(line)
    if match
      to = match[1]

      if to =~ /FRIENDLY HAND/
        puts 'coin for player'
        @on_coin.call(:player) if @on_coin
      elsif to =~ /OPPOSING HAND/
        puts 'coin for opponent'
        @on_coin.call(:opponent) if @on_coin
      end
    end

    # hero
    match = /ProcessChanges.*TRANSITIONING card \[name=(.*).*zone=PLAY.*cardId=(.*).*player=(\d)\] to (.*) \(Hero\)/i.match(line)
    if match

      unless @game_started
        @game_started = true
        @current_turn = 0

        puts '----- Game Started -----'
        @on_game_start.call if @on_game_start
      end

      card_id = match[2].strip
      to      = match[4]

      if to =~ /FRIENDLY PLAY/
        @on_hero.call(:player, card_id) if @on_hero
      else
        @on_hero.call(:opponent, card_id) if @on_hero
      end
    end

    # game end
    match = /\[Asset\\].*name=(victory|defeat)_screen_start/.match(line)
    if match
      status = match[1]

      puts '----- Game End -----'

      case status.downcase
        when 'victory'
          puts 'Victory!'
          @on_game_end.call(:opponent)
        when 'defeat'
          puts 'Defeat'
          @on_game_end.call(:player)
        else
      end

      @game_started = false
    end

  end

end