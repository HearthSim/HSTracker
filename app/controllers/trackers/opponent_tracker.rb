# The opponent tracker window
class OpponentTracker < Tracker

  # accessors used by card count
  attr_accessor :deck_count, :hand_count, :has_coin, :cards, :count_window

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

      NSNotificationCenter.defaultCenter.observe('show_opponent_tracker') do |_|
        show_hide
      end
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

    unless Configuration.fixed_window_names
      self.window.title = 'HSTracker'
    end

    self.has_coin = false
    self.hand_count = 0
    self.deck_count = 30
    display_count
    @table_view.reloadData

    if Configuration.show_card_on_hover
      @card_hover.close if @card_hover
    end
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

  def draw(turn)
    self.hand_count += 1
    if turn == 0 && self.hand_count == 5
      log(:tracker, 'opponent get the coin')
    else
      self.deck_count -= 1 unless self.deck_count.zero?
    end

    display_count
    @table_view.reloadData
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

    display_count
    @table_view.reloadData
  end

  def play(card_id, turn)

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
  end

  def joust(card_id)
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
  end

  def mulligan
    self.hand_count -= 1
    self.deck_count += 1

    display_count
    @table_view.reloadData
  end

  def play_to_hand(card_id, turn, id)
    self.hand_count -= 1
    card = @cards.select { |c| c.card_id == card_id }.first
    if card
      card.count -= 1
    end

    display_count
    @table_view.reloadData
  end

  def play_to_deck(card_id, turn)
    self.deck_count += 1

    display_count
    @table_view.reloadData
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

    if @game_end && row == 0
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
  end

  def resize_window
    frame = SizeHelper.opponent_tracker_frame
    return if frame.nil?
    self.window.setFrame(frame, display: true)
  end
end
