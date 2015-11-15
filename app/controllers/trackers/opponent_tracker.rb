# The opponent tracker window
class OpponentTracker < Tracker

  # accessors used by card count
  attr_accessor :deck_count, :hand_count, :cards, :count_window, :card_huds

  CoinPosition = 4

  def deck_count
    @deck_count ||= 30
  end

  def hand_count
    @hand_count ||= 0
  end

  def init
    super.tap do
      @layout = OpponentTrackerLayout.new
      self.window = @layout.window
      self.window.delegate = self

      @cards = []
      @count_text = ''
      @game_ended = false

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate = self
      @table_view.dataSource = self

      @table_view.setAction 'clicked:'
      @table_view.setTarget self

      if Configuration.hand_count_window == :window
        @count_window = CardCountHud.alloc.initWithPlayer(:opponent)
        @count_window.showWindow(self)
      end

      self.card_huds = (0...10).map do |position|
        card_hud = OpponentCardHud.alloc.initWithPosition(position)
        card_hud.delegate = self
        card_hud
      end

      NSNotificationCenter.defaultCenter.observe('show_opponent_tracker') do |_|
        show_hide
      end

      reset
    end
  end

  def show_hide
    if Configuration.show_opponent_tracker
      self.window.orderFront(self)
    else
      self.window.orderOut(self)
    end
  end

  def clicked(_)
    return unless @game_ended && @table_view.clickedRow.zero?

    log(:tracker, "Want to save a deck for #{@hero.player_class}")
    NSNotificationCenter.defaultCenter.post('open_deck_manager',
                                            nil,
                                            {
                                              cards: @cards,
                                              class: @hero.player_class
                                            })
  end

  ## table datasource
  def numberOfRowsInTableView(_)
    count = @cards.count

    if @game_ended
      count += 1
    end

    if Configuration.hand_count_window == :tracker
      count += 1
    end

    count
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    cell = nil

    if @game_ended
      if row == 0
        cell = ButtonCellView.new
        cell.delegate = self
        cell.setNeedsDisplay true
      end
    end

    if cell.nil?
      if @game_ended
        row -= 1
      end
      card = @cards[row]

      if card
        @cells ||= {}
        cell = @cells[card.card_id] if @cells[card.card_id]

        cell ||= CardCellView.new
        cell.card = card
        cell.side = :opponent
        cell.delegate = self

        @cells[card.card_id] = cell
      else
        cell = CountTextCellView.new
        cell.text = @count_text
      end
    end

    cell
  end

  # disable selection
  def selectionShouldChangeInTableView(tableView)
    false
  end

  # game events
  def game_end
    @game_ended = true
    self.card_huds.each do |card_hud|
      card_hud.text = nil
    end
    (0..10).each do |i|
      @marks[i] = { age: -1, info: :none }
    end
    reload_card_huds

    if Configuration.reset_on_end
      @count_text = nil
      reset
    else
      @table_view.reloadData
    end
  end

  def game_start
    log(:tracker, 'Opponent reset card')
    @game_ended = false
    reset
  end

  def reset
    @cards = []
    @marks ||= {}

    unless Configuration.fixed_window_names
      self.window.title = 'HSTracker'
    end

    self.hand_count = 0
    log :opponent_tracker, reset: self.hand_count
    self.deck_count = 30
    display_count
    @table_view.reloadData

    if Configuration.show_card_on_hover
      @card_hover.close if @card_hover
    end

    (0..10).each do |i|
      @marks[i] = { age: -1, info: :none }
    end

    @opponent_card_hud_hover.close if @opponent_card_hud_hover

    reload_card_huds
  end

  def set_hero(hero_id)
    @hero = Card.hero(hero_id)
    # how @hero.player_class can be nil ?
    if @hero && @hero.player_class && !Configuration.fixed_window_names
      self.window.setTitle @hero.player_class._
    end
  end

  def get_to_deck(card_id, turn)
    self.deck_count += 1

    display_count
    @table_view.reloadData
  end

  def turn_start(turn)
    @last_played_card_id = nil
    @last_jousted_card_id = nil
  end

  def draw(turn)
    self.hand_count += 1
    if turn == 0 && self.hand_count == 5
      log(:tracker, 'opponent get the coin')
      @marks[CoinPosition] = { age: turn, info: :coin, card: 'GAME_005' }
    else
      self.deck_count -= 1 unless self.deck_count.zero?

      if @last_played_card_id == 'AT_058'
        @marks[self.hand_count - 1][:info] = :jousted
        @marks[self.hand_count - 1][:info] = @last_jousted_card_id
        @marks[self.hand_count - 1] = { age: turn, info: :jousted, card: @last_jousted_card_id }
      else
        @marks[self.hand_count - 1] = { age: turn, info: turn.zero? ? :kept : :none }
      end
    end
    log :opponent_tracker, draw: self.hand_count
    display_count
    @table_view.reloadData
    reload_card_huds
  end

  def deck_discard(card_id, turn)
    card = @cards.select { |c| c.card_id == card_id }.first

    card_is_discarded = true
    if card
      if card_id == 'GVG_035' # Malorne
        if card.count > 0
          card.count -= 1

          card_is_discarded = false
        end
      end

      card.hand_count = 0
      if card_is_discarded
        card.count += 1
      end
    else
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.count = 1
        card.hand_count = 0
        @cards << card
        @cards.sort_cards!
      end
    end

    if card_is_discarded
      self.deck_count -= 1
    else
      self.deck_count == 1
    end

    # if the last is King's Elekk,
    # we remember the jousted card
    if @last_played_card_id == 'AT_058'
      @last_jousted_card_id = card_id
    end

    display_count
    @table_view.reloadData

    reload_card_huds
  end

  def play(card_id, from, turn)
    @last_played_card_id = card_id

    if card_id
      card = @cards.select { |c| c.card_id == card_id }.first
      if card
        card.count += 1
      else
        real_card = Card.by_id(card_id)
        if real_card
          card = PlayCard.from_card(real_card)
          card.count = 1
          card.hand_count = 0
          card.has_changed = true
          @cards << card
          @cards.sort_cards!
        end
      end
    end

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
    @table_view.reloadData
    log :opponent_tracker, play: self.hand_count
    ((from - 1)..9).each do |i|
      @marks[i] = { age: @marks[i + 1][:age], info: @marks[i + 1][:info], card: @marks[i + 1][:card] }
    end

    @marks[9] = { age: -1, info: :none }

    # if the last is King's Elekk,
    # we remember the jousted card
    if @last_played_card_id == 'AT_058'
      @last_jousted_card_id = card_id
    end

    reload_card_huds
  end

  def joust(card_id)
    log :opponent_tracker, opponent_joust: card_id
    card = @cards.select { |c| c.card_id == card_id }.first
    if card && card.is_jousted
      card.is_jousted = false
    elsif card
      # card.count ?
    else
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.count = 0
        card.hand_count = 0
        card.is_jousted = true
        card.has_changed = true
        @cards << card
        @cards.sort_cards!
      end
    end

    if @last_played_card_id

      # if the last is King's Elekk,
      # we remember the jousted card
      if @last_played_card_id == 'AT_058'
        @last_jousted_card_id = card_id
      end
    end
  end

  def mulligan(pos)
    self.hand_count -= 1
    self.deck_count += 1
    log :opponent_tracker, mulligan: self.hand_count
    display_count
    @table_view.reloadData
    @marks[pos - 1][:info] = :mulliganed

    reload_card_huds
  end

  def play_to_hand(card_id, turn, id)
    self.hand_count -= 1
    card = @cards.select { |c| c.card_id == card_id }.first
    if card
      card.count -= 1
    end
    log :opponent_tracker, play_to_hand: self.hand_count
    display_count
    @table_view.reloadData

    @marks[self.hand_count - 1] = { age: turn, info: :returned, card: card_id }

    reload_card_huds
  end

  def play_to_deck(card_id, turn)
    self.deck_count += 1

    display_count
    @table_view.reloadData
  end

  def deck_to_play(card_id)
    log :opponent_tracker, opponent_deck_to_play: card_id
  end

  def remove_from_deck(card_id)
    log :opponent_tracker, opponent_remove_from_deck: card_id
  end

  def secret_trigger(card_id, turn, id)
    return if card_id.nil? || card_id.empty?

    card = @cards.select { |c| c.card_id == card_id }.first
    if card
      card.count += 1
    else
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.count = 1
        card.hand_count = 0
        card.has_changed = true
        @cards << card
        @cards.sort_cards!
      end
    end

    display_count
    @table_view.reloadData
  end

  def get(turn, id)
    self.hand_count += 1
    display_count
    @table_view.reloadData

    return unless @marks || @marks[self.hand_count - 1]
    @marks[self.hand_count - 1][:age] = turn

    if @marks[self.hand_count - 1][:info] != :coin
      @marks[self.hand_count - 1][:info] = :stolen
    end

    reload_card_huds
  end

  def tableView(tableView, heightOfRow: row)
    case Configuration.card_layout
      when :small
        ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
      when :medium
        ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
      else
        ratio = 1.0
    end

    if @game_ended && row == 0
      35.0 / ratio
    elsif Configuration.hand_count_window == :tracker && numberOfRowsInTableView(@table_view) - 1 == row
      50.0 / ratio
    else
      case Configuration.card_layout
        when :small
          TrackerLayout::KSmallRowHeight
        when :medium
          TrackerLayout::KMediumRowHeight
        else
          TrackerLayout::KRowHeight
      end
    end
  end

  def display_count
    text = :hand._(count: self.hand_count)
    text << ' / '
    text << :deck._(count: self.deck_count)

    if Configuration.hand_count_window == :tracker
      @count_text = text
    elsif Configuration.hand_count_window == :window
      @count_window.text = text
    end
  end

  def reload_card_huds
    return unless Configuration.opponent_overlay

    self.card_huds.each do |card_hud|
      age = @marks[card_hud.position][:age]
      if age == -1
        card_hud.window.orderOut(self)
        next
      end

      card_hud.window.orderFront(self)
      text = case @marks[card_hud.position][:info]
               when :coin
                 :coin_abbr._
               when :returned
                 :returned_abbr._
               when :stolen
                 :stolen_abbr._
               when :jousted
                 :joust_abbr._
               when :mulliganed
                :mulligan_abbr._
              when :kept
                :kept_abbr._
               else
                 ''
             end
      card_hud.card = @marks[card_hud.position][:card]
      card_hud.text = (age.to_f / 2).round.to_s + "\n" + text
      card_hud.resize_window_with_cards(self.hand_count)
    end
  end

  def window_transparency
    @table_view.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end

  def hand_count_window_changed
    if @count_window
      @count_window.window.orderOut(self)
      @count_window = nil
    end
    @table_view.reloadData if @table_view

    if Configuration.hand_count_window == :window
      @count_window = CardCountHud.alloc.initWithPlayer(:opponent)
      @count_window.showWindow(self)
    end

    display_count
    @table_view.reloadData if @table_view
  end

  def set_level(level)
    window.setLevel level
    if @count_window
      @count_window.window.setLevel level
    end
    self.card_huds.each do |card_hud|
      card_hud.set_level level
    end
  end

  def resize_window
    frame = SizeHelper.opponent_tracker_frame
    return if frame.nil?
    self.window.setFrame(frame, display: true)

    self.card_huds.each do |card_hud|
      card_hud.resize_window_with_cards(self.hand_count)
    end
  end

  def hover_opponent_card(hud)
    card = hud.card

    return if card.nil?

    if @opponent_card_hud_hover.nil?
      @opponent_card_hud_hover = CardHover.new
    end

    @opponent_card_hud_hover.card = Card.by_id(card)
    @opponent_card_hud_hover.showWindow(self.window)
    frame = hud.window.frame
    point = [frame.origin.x + frame.size.width + 10, frame.origin.y]
    @opponent_card_hud_hover.window.setFrameTopLeftPoint(point)
  end

  def out_opponent_card(hud)
    @opponent_card_hud_hover.close if @opponent_card_hud_hover
  end

end
