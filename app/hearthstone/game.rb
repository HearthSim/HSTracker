class Game
  include CDQ

  attr_accessor :player_tracker, :opponent_tracker
  attr_accessor :timer_hud
  attr_accessor :start_date, :end_date
  attr_accessor :game_mode, :entities, :player_id, :opponent_id, :wait_controller, :joust_reveals
  attr_accessor :awaiting_ranked_detection, :found_ranked, :last_asset_unload, :game_started

  def initialize
    @game_started = false
    reset
  end

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def with_deck(current_deck)
    @current_deck = current_deck
  end

  def choose_correct_deck
    # when HSTracker starts and the game is already started, player_tracker window
    # can not still be visible...
    # wait for it
    unless player_tracker.window.isVisible
      Dispatch::Queue.concurrent.after (0.25) do
        choose_correct_deck
      end
      return
    end

    @has_been_prompted_back_deck = true

    popup = NSPopUpButton.new
    popup.frame = [[0, 0], [299, 24]]

    Deck.where(is_active: true)
      .and(:player_class).eq(@current_player_class)
      .sort_by(:name, case_insensitive: true).each do |deck|

      item = NSMenuItem.alloc.initWithTitle(deck.name, action: nil, keyEquivalent: '')
      popup.menu.addItem item
    end

    response = NSAlert.alert(:invalid_deck._,
                             buttons: [:ok._, :cancel._],
                             view: popup,
                             force_top: true)
    if response == NSAlertFirstButtonReturn
      choosen = popup.selectedItem.title
      deck = Deck.by_name(choosen)
      return if deck.nil?

      with_deck(deck)
      if player_tracker
        Dispatch::Queue.main.after (0.5) do
          player_tracker.show_deck(deck.playable_cards, deck.name)
          Dispatch::Queue.concurrent.after (0.25) do
            Hearthstone.instance.log_observer.restart_last_game
          end
        end
      end
      if Configuration.remember_last_deck
        Configuration.last_deck_played = "#{deck.name}##{deck.version}"
      end
    end
  end

  def handle_end_game
    if @current_deck.nil?
      log(:engine, 'No current deck, ignore game')
      return
    end

    if game_mode != :ranked
      detect_mode(3) do |found|
        if found
          log(:engine, 'Game mode detected as ranked')
          handle_end_game
        end
      end
    end

    if game_mode == :ranked && @current_rank.nil?
      wait_rank(5) do |found|
        if found
          log(:engine, "Game ranked, get rank #{@current_rank}")
          handle_end_game
        end
      end
    end

    # with a too long timeout, and if you already started a new game, @vars will be resetted
    # a the time the fail block is called...

    cards = []
    if @opponent_cards
      cards = @opponent_cards.map { |card| { id: card.card_id, count: card.count } }
    end

    @start_date ||= NSDate.new

    _player_class = @current_deck.player_class
    _current_deck = @current_deck
    _current_deck_name = _current_deck.name
    _has_coin = @has_coin
    _current_turn = @current_turn
    _duration = (@end_date.timeIntervalSince1970 - @start_date.timeIntervalSince1970).to_i
    _deck_id = @current_deck.hearthstats_id
    _deck_version_id = @current_deck.hearthstats_version_id
    _ranklvl = @current_rank
    _oppcards = cards
    _start_date = @start_date
    date_formatter = NSDateFormatter.new
    date_formatter.timeZone = NSTimeZone.timeZoneWithName('UTC')
    date_formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
    _created_at = date_formatter.stringFromDate(_start_date)
    _oppclass = @current_opponent ? @current_opponent.player_class : nil
    _oppname = @opponent_name || nil
    _game_mode = game_mode.to_s

    if game_mode == :ranked && @current_rank
      # stats have a game_mode... it will be supported in a future version
      log(:engine, stats: @game_result_win, against: _oppclass, with_deck: _current_deck_name, rank: _ranklvl)
      Statistic.create opponent_class: _oppclass,
                       opponent_name: _oppname,
                       win: (@game_result_win == :win),
                       deck: _current_deck,
                       rank: _ranklvl,
                       game_mode: _game_mode,
                       duration: _duration,
                       turns: _current_turn,
                       has_coin: _has_coin,
                       created_at: _start_date

      cdq.save
      @game_saved = true

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
        _game_mode = case game_mode
                      when :ranked
                        'Ranked'
                      when :arena
                        'Arena'
                      when :brawl
                        'Brawl'
                      else
                        'Casual'
                    end

        data = { class: _player_class,
                 mode: _game_mode,
                 result: game_result,
                 coin: _has_coin.to_s,
                 numturns: _current_turn,
                 duration: _duration,
                 deck_id: _deck_id,
                 deck_version_id: _deck_version_id,
                 oppclass: _oppclass,
                 oppname: _oppname,
                 notes: nil,
                 ranklvl: _ranklvl,
                 oppcards: cards,
                 created_at: _created_at
        }
        # todo, add :log (see match_log.json)

        if _deck_id.nil? || _deck_id.zero?
          response = NSAlert.alert(:deck_save._,
                                   buttons: [:ok._, :cancel._],
                                   informative: :deck_not_saved_hearthstats._,
                                   force_top: true)
          if response == NSAlertFirstButtonReturn
            HearthStatsAPI.post_deck(_current_deck) do |status, deck|
              if status
                # update deck
                cdq.save

                self.with_deck(deck)
                data[:deck_id] = deck.hearthstats_id
                data[:deck_version_id] = deck.hearthstats_version_id
                HearthStatsAPI.post_game_result(data) do |success|
                  # save for later
                  save_match(data, cards) unless success
                end
              else
                error(:error, "Error while posting deck #{@current_deck.name}")
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
    end
  end

  def save_match(data, cards)
    created_at = data[:created_at]
    if created_at.respond_to?(:string_with_format)
      created_at = created_at.string_with_format("yyyy-MM-dd'T'HH:mm", unicode: true)
    end

    # let's be sure...
    if created_at.respond_to?(:to_s)
      created_at = created_at.to_s
    end

    match = HearthstatsMatch.create player_class: data[:class],
                                    mode: data[:mode],
                                    result: data[:result],
                                    coin: data[:coin],
                                    numturns: data[:numturns],
                                    duration: data[:duration],
                                    deck_id: data[:deck_id],
                                    deck_version_id: data[:deck_version_id],
                                    oppclass: data[:oppclass],
                                    oppname: data[:oppname],
                                    notes: data[:notes],
                                    ranklvl: data[:ranklvl],
                                    match_created_at: created_at

    cards.each do |c|
      HearthstatsMatchCard.create card_id: c[:id],
                                  count: c[:count],
                                  hearthstats_match: match
    end

    cdq.save
  end

  def wait_rank(timeout_sec, &block)
    log(:engine, 'waiting for rank')
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
  def game_mode=(game_mode)
    log(:engine, "Player in game mode #{game_mode}")
    @game_mode = game_mode
  end

  def entities
    @entities ||= {}
  end

  def player_rank(rank)
    log(:engine, "You are rank #{rank}")
    @current_rank = rank
  end

  def reset
    log(:engine, 'Reset data')
    @entities = {}
    @tmp_entities = []
    @player_id = nil
    @opponent_id = nil
    @wait_controller = nil
    @joust_reveals = 0

    @current_turn = -1
    @current_entity = nil

    @game_saved = false
    @game_result_win = nil
    @current_player_class = nil
    @current_opponent = nil
    @current_turn = 0
    @opponent_cards = nil
    @has_coin = false
    @has_been_prompted_back_deck = false
  end

  def game_start
    return if @game_started
    @game_started = true

    log(:engine, '----- Game Started -----')
    @start_date = NSDate.new
    player_tracker.game_start
    opponent_tracker.game_start

    reset
  end

  def concede
    log(:engine, 'Game has been conceded :(')
  end

  def win
    log(:engine, 'You win ¯\_(ツ)_/¯')
    @game_result_win = :win
  end

  def loss
    log(:engine, 'You loose :(')
    @game_result_win = :loss
  end

  def tied
    log(:engine, 'You loose / game tied:(')
    @game_result_win = :draw
  end

  def game_end
    log(:engine, '----- Game End -----')
    @game_started = false
    @end_date = NSDate.new

    @opponent_cards = opponent_tracker.cards
    handle_end_game

    player_tracker.game_end
    opponent_tracker.game_end
    timer_hud.game_end
  end

  def turn_start(player, turn)
    log(:engine, player: :turn, turn: turn)
    @current_turn = turn

    timer_hud.restart(player)
    opponent_tracker.turn_start(turn) if player == :opponent
  end

  ## player events
  def player_name(name)
    log(:engine, player: name)
  end

  def player_get_to_deck(card_id, turn)
    log(:engine, player: :get_to_deck, card_id: card_id, card: card(card_id), turn: turn)
    return if card_id.nil? || card_id.empty?

    player_tracker.get_to_deck(card_id)
  end

  def player_hero(hero_id)
    hero = Card.hero(hero_id)
    if hero
      @current_player_class = hero.player_class
      log(:engine, player: hero.name, hero_id: hero_id)
      player_tracker.set_hero(hero_id)

      #if Configuration.prompt_deck && @current_deck.player_class != hero.player_class && !@has_been_prompted_back_deck
      #  choose_correct_deck
      #end
    end
  end

  def player_draw(card_id, turn)
    log(:engine, player: :draw, card_id: card_id, card: card(card_id), turn: turn)
    return if card_id.nil? || card_id.empty?

    if card_id == 'GAME_005'
      @has_coin = true
      player_get(card_id, turn)
    else
      player_tracker.draw(card_id)
    end
  end

  def player_deck_discard(card_id, turn)
    log(:engine, player: :discard_to_deck, card_id: card_id, card: card(card_id), turn: turn)
    player_tracker.deck_discard(card_id)
  end

  def player_secret_played(card_id, turn, from_deck)
    log(:engine, player: :play_secret, card_id: card_id, card: card(card_id), from_deck: from_deck, turn: turn)
    if from_deck
      player_tracker.deck_discard(card_id)
    else
      player_tracker.hand_discard(card_id)
    end
  end

  def player_play(card_id, turn)
    log(:engine, player: :play, card_id: card_id, card: card(card_id), turn: turn)
    return if card_id.nil? || card_id.empty?

    player_tracker.play(card_id)
  end

  def player_hand_discard(card_id, turn)
    return if card_id.nil? || card_id.empty?

    log(:engine, player: :discard_from_hand, card_id: card_id, card: card(card_id), turn: turn)
    player_tracker.hand_discard(card_id)
  end

  def player_mulligan(card_id)
    log(:engine, player: :mulligan, card_id: card_id, card: card(card_id))
    player_tracker.mulligan(card_id)
    timer_hud.mulligan_done(:player)
  end

  def player_back_to_hand(card_id, turn)
    log(:engine, player: :card_back_to_hand, card_id: card_id, card: card(card_id), turn: turn)
    return if card_id.nil? || card_id.empty?

    player_tracker.get(card_id, true, turn)
  end

  def player_play_to_deck(card_id, turn)
    log(:engine, player: :play_to_deck, card_id: card_id, card: card(card_id), turn: turn)
    return if card_id.nil? || card_id.empty?

    player_tracker.play_to_deck(card_id)
  end

  def player_deck_to_play(card_id, turn)
    log(:engine, player: :deck_to_play, card_id: card_id, card: card(card_id), turn: turn)
    player_tracker.deck_to_play(card_id)
  end

  def player_get(card_id, turn)
    log(:engine, player: :get, card_id: card_id, card: card(card_id), turn: turn)
    return if card_id.nil? || card_id.empty?

    player_tracker.get(card_id, false, turn)
  end

  def player_fatigue(value)
    log(:engine, player: :fatigue, value: value)
  end

  def player_joust(card_id, turn)
    log(:engine, player: :joust, card_id: card_id, card: card(card_id), turn: turn)
    player_tracker.joust(card_id)
  end

  def player_remove_from_deck(card_id, turn)
    log(:engine, player: :remove_from_deck, card_id: card_id, card: card(card_id), turn: turn)
    player_tracker.remove_from_deck(card_id)
  end

  ## opponent events
  def opponent_name(name)
    log(:engine, opponent: name)
    @opponent_name = name
  end

  def opponent_get_to_deck(card_id, turn)
    log(:engine, opponent: :get_to_deck, card_id: card_id, card: card(card_id), turn: turn)
    opponent_tracker.get_to_deck(card_id, turn)
  end

  def opponent_hero(hero_id)
    @current_opponent = Card.hero(hero_id)
    if @current_opponent
      hero = @current_opponent.name
      log(:engine, opponent: hero, hero_id: hero_id)
      opponent_tracker.set_hero(hero_id)
    end
  end

  def opponent_draw(turn)
    log(:engine, opponent: :draw, turn: turn)
    opponent_tracker.draw(turn)
  end

  def opponent_deck_discard(card_id, turn)
    log(:engine, opponent: :discard_to_deck, card_id: card_id, card: card(card_id), turn: turn)
    opponent_tracker.deck_discard(card_id, turn)
  end

  def opponent_secret_played(card_id, from, turn, from_deck, id)
    log(:engine, opponent: :play_secret, card_id: card_id, card: card(card_id), from: from, id: id, from_deck: from_deck, turn: turn)

    if from_deck
      opponent_tracker.deck_discard(card_id, turn)
    else
      opponent_tracker.play(card_id, from, turn)
    end
  end

  def opponent_play(card_id, from, turn)
    log(:engine, opponent: :play, card_id: card_id, card: card(card_id), from: from, turn: turn)
    opponent_tracker.play(card_id, from, turn)
  end

  def opponent_hand_discard(card_id, from, turn)
    log(:engine, opponent: :discard_from_hand, card_id: card_id, card: card(card_id), from: from, turn: turn)
    opponent_tracker.play(card_id, from, turn)
  end

  def opponent_mulligan(from)
    log(:engine, opponent: :mulligan, from: from)
    opponent_tracker.mulligan(from)
    timer_hud.mulligan_done(:opponent)
  end

  def opponent_play_to_hand(card_id, turn, id)
    log(:engine, opponent: :play_to_hand, card_id: card_id, card: card(card_id), id: id, turn: turn)
    opponent_tracker.play_to_hand(card_id, turn, id)
  end

  def opponent_play_to_deck(card_id, turn)
    log(:engine, opponent: :play_to_deck, card_id: card_id, card: card(card_id), turn: turn)
    opponent_tracker.play_to_deck(card_id, turn)
  end

  def opponent_deck_to_play(card_id, turn)
    log(:engine, opponent: :deck_to_play, card_id: card_id, card: card(card_id), turn: turn)
    opponent_tracker.deck_to_play(card_id)
  end

  def opponent_secret_trigger(card_id, turn, id)
    log(:engine, opponent: :secret_trigger, card_id: card_id, card: card(card_id), id: id, turn: turn)
    opponent_tracker.secret_trigger(card_id, turn, id)
  end

  def opponent_get(turn, id)
    log(:engine, opponent: :get, id: id, turn: turn)
    opponent_tracker.get(turn, id)
  end

  def opponent_fatigue(value)
    log(:engine, opponent: :fatigue, value: value)
  end

  def opponent_joust(card_id, turn)
    return if card_id.nil? or card_id.empty?
    log(:engine, opponent: :joust, card_id: card_id, card: card(card_id), turn: turn)
    opponent_tracker.joust(card_id)
  end

  def opponent_remove_from_deck(card_id, turn)
    log(:engine, opponent: :remove_from_deck, card_id: card_id, card: card(card_id), turn: turn)
    opponent_tracker.remove_from_deck(card_id)
  end

  def turn_number
    return 0 unless is_mulligan_done

    if @current_turn == -1
      player = entities.select { |_, val| val.has_tag?(GameTag::FIRST_PLAYER) }.values.first
      unless player.nil?
        @current_turn = player.tag(GameTag::CONTROLLER) == player_id ? 0 : 1
      end
    end

    entity = entities.values.first
    if entity
      return (entity.tag(GameTag::TURN).to_i + (@current_turn == -1 ? 0 : @current_turn)) / 2
    end

    0
  end

  def is_mulligan_done
    player = entities.select { |_, val| val.is_player }.values.first
    opponent = entities.select { |_, val| val.has_tag?(GameTag::PLAYER_ID) && !val.is_player }.values.first

    return false if player.nil? || opponent.nil?

    player.tag(GameTag::MULLIGAN_STATE) == Mulligan::DONE && opponent.tag(GameTag::MULLIGAN_STATE) == Mulligan::DONE
  end

  def detect_mode(timeout_sec, &block)
    log(:analyzer, 'waiting for mode')
    Dispatch::Queue.concurrent.async do
      @awaiting_ranked_detection = true
      @waiting_for_first_asset_unload = true
      @found_ranked = false
      @last_asset_unload = NSDate.new.timeIntervalSince1970

      timeout = (Time.now + timeout_sec.seconds).to_f
      while @waiting_for_first_asset_unload || (Time.now.to_f - @last_asset_unload) < timeout
        NSThread.sleepForTimeInterval(0.1)
        break if @found_ranked
      end

      Dispatch::Queue.main.async do
        block.call(@found_ranked) if block
      end
    end
  end

  private
  def card(card_id)
    card = Card.by_id(card_id)
    return card.name if card
    'Unknown card'
  end

  def notify(event, args={})
    NSNotificationCenter.defaultCenter.post(event, self, args)
  end

end
