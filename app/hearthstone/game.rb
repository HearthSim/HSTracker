class Game
  include CDQ

  Log = Motion::Log

  attr_accessor :player_tracker, :opponent_tracker

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def with_deck(current_deck)
    @current_deck = current_deck
  end

  def save_stats
    return if @game_saved or @game_result_win.nil? or @current_deck.nil? or @current_opponent.nil? or @game_mode != :ranked
    Log.verbose "stats : #{@game_result_win}, against : #{@current_opponent.player_class}, with deck : #{@current_deck.name}"

    Statistic.create :opponent_class => @current_opponent.player_class,
                     :win            => (@game_result_win == :win),
                     :deck           => @current_deck
    cdq.save
    @game_saved = true
  end

  ## game events

  def game_mode(game_mode)
    Log.debug "Player in game mode #{game_mode}"
    @game_mode = game_mode

    save_stats
  end

  def player_rank(rank)
    Log.debug "You are rank #{rank}"
    @current_rank = rank

    save_stats
  end

  def game_start
    Log.debug '----- Game Started -----'
    player_tracker.game_start
    opponent_tracker.game_start

    @game_saved = false
    @game_result_win  = nil
    @current_opponent = nil
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
  end

  def game_end
    Log.debug '----- Game End -----'
    save_stats

    player_tracker.game_end
    opponent_tracker.game_end
  end

  def turn_start(player, turn)
    log(player, "turn : #{turn}")
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