class Game
  include CDQ

  Log = Motion::Log

  attr_accessor :player_tracker, :opponent_tracker, :start_date, :end_date

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def with_deck(current_deck)
    @current_deck = current_deck
  end

  def handle_end_game
    if @current_deck.nil?
      Log.verbose 'No current deck, ignore game'
      return
    end

    if @game_mode != :ranked
      Hearthstone.instance.log_observer.detect_mode(3) do |found|
        if found
          Log.verbose 'Game mode detected as ranked'
          handle_end_game
        end
      end
    end

    if @game_mode == :ranked and @current_rank.nil?
      wait_rank(5) do |found|
        if found
          Log.verbose "Game ranked, get rank #{@current_rank}"
          handle_end_game
        end
      end
    end

    if @game_mode == :ranked && @current_rank
      if Configuration.use_hearthstats
        game_result = case @game_result_win
                        when :win
                          'Win'
                        when :loss
                          'Loss'
                        when :draw
                          'Draw'
                        else
                          'None'
                      end
        game_mode   = case @game_mode
                        when :ranked
                          'Ranked'
                        when :arena
                          'Arena'
                        else
                          'Casual'
                      end
        cards       = []
        if @opponent_cards
          cards = @opponent_cards.map { |card| { id: card.card_id, count: card.count } }
        end
        data = { :class           => @current_deck.player_class,
                 :mode            => game_mode,
                 :result          => game_result,
                 :coin            => @has_coin.to_s,
                 :numturns        => @current_turn,
                 :duration        => (@end_date.timeIntervalSince1970 - @start_date.timeIntervalSince1970).to_i,
                 :deck_id         => @current_deck.hearthstats_id,
                 :deck_version_id => @current_deck.hearthstats_version_id,
                 :oppclass        => @current_opponent.player_class,
                 :oppname         => @opponent_name || nil,
                 :notes           => nil,
                 :ranklvl         => @current_rank,
                 :oppcards        => cards,
                 :created_at      => @start_date.string_with_format("yyyy-MM-dd'T'HH:mm", :unicode => true)
        }

        if @current_deck.hearthstats_id.nil? or @current_deck.hearthstats_id.zero?
          response = NSAlert.alert('Deck save'._,
                                   :buttons     => ['OK'._, 'Cancel'._],
                                   :informative => 'Your deck is not saved on HearthStats. Do you want to save it now ?'._,
                                   :force_top   => true)
          if response == NSAlertFirstButtonReturn
            HearthStatsAPI.post_deck(@current_deck) do |status|
              if status
                data[:deck_id]         = @current_deck.hearthstats_id
                data[:deck_version_id] = @current_deck.hearthstats_version_id
                HearthStatsAPI.post_game_result(data) do |success|
                  # save for later
                  save_match(data, cards) unless success
                end
              else
                Log.error "Error while posting deck #{@current_deck.name}"
              end
            end
          end
        else
          HearthStatsAPI.post_game_result(data) do |success|
            # save for later
            save_match(data, cards) unless success
          end
        end
      end

      # stats have a game_mode... it will be supported in a future version
      Log.verbose "stats : #{@game_result_win} against : #{@current_opponent.player_class} with deck : #{@current_deck.name} at rank : #{@current_rank}"
      Statistic.create :opponent_class => @current_opponent.player_class,
                       :opponent_name  => @opponent_name,
                       :win            => (@game_result_win == :win),
                       :deck           => @current_deck,
                       :rank           => @current_rank,
                       :game_mode      => @game_mode.to_s,
                       :duration       => (@end_date.timeIntervalSince1970 - @start_date.timeIntervalSince1970).to_i,
                       :turns          => @current_turn,
                       :has_coin       => @has_coin,
                       :created_at     => @start_date
      cdq.save
      @game_saved = true
    end
  end

  def save_match(data, cards)
    data[:player_class] = data[:class]
    data.delete_if { |key, _| key == :class }

    mp :data => data, :cards => cards
    match = HearthstatsMatch.create data

    cards.each do |c|
      HearthstatsMatchCard.create :card_id           => c[:id],
                                  :count             => c[:count],
                                  :hearthstats_match => match
    end

    cdq.save
  end

  def wait_rank(timeout_sec, &block)
    Log.verbose 'waiting for rank'
    Dispatch::Queue.concurrent.async do
      @found_rank = false

      timeout = timeout_sec.seconds.after(NSDate.now).timeIntervalSince1970
      while (NSDate.now.timeIntervalSince1970 - @last_asset_unload) < timeout
        NSThread.sleepForTimeInterval(0.1)
        break if @found_rank
      end

      Dispatch::Queue.main.async do
        block.call(@found_rank) if block
      end
    end
  end

  ## game events
  def game_mode(game_mode)
    Log.debug "Player in game mode #{game_mode}"
    @game_mode = game_mode
  end

  def player_rank(rank)
    Log.debug "You are rank #{rank}"
    @current_rank = rank
  end

  def game_start
    Log.debug '----- Game Started -----'
    @start_date = NSDate.new
    player_tracker.game_start
    opponent_tracker.game_start

    @game_saved       = false
    @game_result_win  = nil
    @current_opponent = nil
    @current_turn     = 0
    @opponent_cards   = nil
    @has_coin         = false
  end

  def concede
    Log.debug 'Game has been conceded :('
  end

  def win
    Log.debug 'You win ¯\_(ツ)_/¯'
    @game_result_win = :win
  end

  def loss
    Log.debug 'You loose :('
    @game_result_win = :loss
  end

  def tied
    Log.debug 'You loose / game tied:('
    @game_result_win = :draw
  end

  def game_end
    Log.debug '----- Game End -----'
    @end_date = NSDate.new

    @opponent_cards = opponent_tracker.cards
    handle_end_game

    player_tracker.game_end
    opponent_tracker.game_end
  end

  def turn_start(player, turn)
    log(player, "turn : #{turn}")
    @current_turn = turn
  end

  ## player events
  def player_name(name)
    log(:player, "name is #{name}")
  end

  def player_get_to_deck(card_id, turn)
    log(:player, "get to deck #{card_id} (#{card(card_id)})", turn)
    return if card_id.nil? or card_id.empty?

    player_tracker.get_to_deck(card_id)
  end

  def player_hero(hero_id)
    log(:player, "hero is #{hero_id} (#{Card.hero(hero_id).name})")
    player_tracker.set_hero(hero_id)
  end

  def player_draw(card_id, turn)
    log(:player, "draw #{card_id} (#{card(card_id)})", turn)
    return if card_id.nil? or card_id.empty?

    if card_id == 'GAME_005'
      @has_coin = true
      player_get(card_id, turn)
    else
      player_tracker.draw(card_id)
    end
  end

  def player_deck_discard(card_id, turn)
    log(:player, "discard to deck #{card_id} (#{card(card_id)})", turn)
    player_tracker.deck_discard(card_id)
  end

  def player_secret_played(card_id, turn, from_deck)
    log(:player, "play secret #{card_id} (#{card(card_id)}) (from_deck: #{from_deck})", turn)
    if from_deck
      player_tracker.deck_discard(card_id)
    else
      player_tracker.hand_discard(card_id)
    end
  end

  def player_play(card_id, turn)
    log(:player, "play #{card_id} (#{card(card_id)})", turn)
    return if card_id.nil? or card_id.empty?

    player_tracker.play(card_id)
  end

  def player_hand_discard(card_id, turn)
    return if card_id.nil? or card_id.empty?

    log(:player, "discard from hand #{card_id} (#{card(card_id)})", turn)
    player_tracker.hand_discard(card_id)
  end

  def player_mulligan(card_id)
    log(:player, "mulligan #{card_id} (#{card(card_id)})")
    player_tracker.mulligan(card_id)
  end

  def player_back_to_hand(card_id, turn)
    log(:player, "card back to hand #{card_id} (#{card(card_id)})", turn)
    return if card_id.nil? or card_id.empty?

    player_tracker.get(card_id, true, turn)
  end

  def player_play_to_deck(card_id, turn)
    log(:player, "play to deck #{card_id} (#{card(card_id)})", turn)
    return if card_id.nil? or card_id.empty?

    player_tracker.play_to_deck(card_id)
  end

  def player_get(card_id, turn)
    log(:player, "get #{card_id} (#{card(card_id)})", turn)
    return if card_id.nil? or card_id.empty?

    player_tracker.get(card_id, false, turn)
  end

  def player_fatigue(value)
    log(:player, "take #{value} from fatigue")
  end

  ## opponent events
  def opponent_name(name)
    log(:opponent, "name is #{name}")
    @opponent_name = name
  end

  def opponent_get_to_deck(card_id, turn)
    log(:opponent, "get to deck #{card_id} (#{card(card_id)})", turn)
    opponent_tracker.get_to_deck(card_id, turn)
  end

  def opponent_hero(hero_id)
    @current_opponent = Card.hero(hero_id)
    if @current_opponent
      hero = @current_opponent.name
      log(:opponent, "hero is #{hero_id} (#{hero})")
      opponent_tracker.set_hero(hero_id)
    end
  end

  def opponent_draw(turn)
    log(:opponent, 'draw', turn)
    opponent_tracker.draw(turn)
  end

  def opponent_deck_discard(card_id, turn)
    log(:opponent, "discard to deck #{card_id} (#{card(card_id)})", turn)
    opponent_tracker.deck_discard(card_id, turn)
  end

  def opponent_secret_played(card_id, from, turn, from_deck, id)
    log(:opponent, "play secret #{card_id} (#{card(card_id)}) (from: #{from}, id: #{id}, from_deck: #{from_deck})", turn)

    if from_deck
      opponent_tracker.deck_discard(card_id, turn)
    else
      opponent_tracker.play(card_id, turn)
    end
  end

  def opponent_play(card_id, from, turn)
    log(:opponent, "play #{card_id} (#{card(card_id)}) (from: #{from})", turn)
    opponent_tracker.play(card_id, turn)
  end

  def opponent_hand_discard(card_id, from, turn)
    log(:opponent, "discard from hand #{card_id} (#{card(card_id)}) (from: #{from})", turn)
    opponent_tracker.play(card_id, turn)
  end

  def opponent_mulligan(from)
    log(:opponent, "mulligan (from: #{from})")
    opponent_tracker.mulligan
  end

  def opponent_play_to_hand(card_id, turn, id)
    log(:opponent, "play to hand #{card_id} (#{card(card_id)}) (id: #{id})", turn)
    opponent_tracker.play_to_hand(card_id, turn, id)
  end

  def opponent_play_to_deck(card_id, turn)
    log(:opponent, "play to deck #{card_id} (#{card(card_id)})", turn)
    opponent_tracker.play_to_deck(card_id, turn)
  end

  def opponent_secret_trigger(card_id, turn, id)
    log(:opponent, "secret trigger #{card_id} (#{card(card_id)}) (id: #{id})", turn)
    opponent_tracker.secret_trigger(card_id, turn, id)
  end

  def opponent_get(turn, id)
    log(:opponent, "get (id: #{id})", turn)
    opponent_tracker.get(turn, id)
  end

  def opponent_fatigue(value)
    log(:opponent, "take #{value} from fatigue")
  end

  private
  def card(card_id)
    card = Card.by_id(card_id)
    return card.name if card
    'Unknown card'
  end

  def log(player, str, turn=nil)
    message = "#{player}"
    message << " | turn : #{turn}" unless turn.nil?
    message << " | #{str}"

    Log.verbose message
  end

  def notify(event, args={})
    NSNotificationCenter.defaultCenter.post(event, self, args)
  end

end