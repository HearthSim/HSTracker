# The player tracker window
class PlayerTracker < Tracker

  attr_accessor :cards, :playing_cards, :count_window

  # accessors used by card count
  attr_accessor :deck_count, :hand_count

  def init
    super.tap do
      @layout = PlayerTrackerLayout.new
      self.window = @layout.window
      self.window.delegate = self

      @cards = {}
      @playing_cards = []
      @count_text = ''

      self.hand_count = 0
      self.deck_count = 30

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate = self
      @table_view.dataSource = self

      if Configuration.hand_count_window == :window
        @count_window = CardCountHud.alloc.initWithPlayer(:player)
        @count_window.showWindow(self)
      end
    end
  end

  def show_deck(deck, name)
    self.cards = deck
    self.title = name
    reset
  end

  def title=(value)
    unless Configuration.fixed_window_names
      self.window.title = value
    end
  end

  def cards=(cards)
    @cells = {}
    @cards = {}
    @playing_cards = []
    cards.each do |card|
      @cards[card.card_id] = card.count
      @playing_cards << PlayCard.from_card(card)
    end

    @table_view.reloadData
  end

  def clear
    @cells = {}
    @cards = {}
    @playing_cards = []
    @table_view.reloadData
  end

  ## table datasource
  def numberOfRowsInTableView(_)
    count = @playing_cards.count

    if Configuration.hand_count_window == :tracker
      count += 1
    end

    count
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    card = @playing_cards[row]

    if card
      @cells ||= {}
      cell = @cells[card.card_id] if @cells[card.card_id]

      cell ||= CardCellView.new
      cell.card = card
      cell.side = :player
      cell.delegate = self

      if card.has_changed
        card.has_changed = false
        cell.flash
      end

      @cells[card.card_id] = cell
    else
      cell = CountTextCellView.new
      cell.text = @count_text
    end

    cell
  end

  # disable selection
  def selectionShouldChangeInTableView(tableView)
    false
  end

  # game events
  def game_end
    if Configuration.reset_on_end
      reset
    end
  end

  def game_start
    log(:tracker, 'Player reset card')
    reset
  end

  def reset
    @count_text = nil
    @playing_cards = []

    @cards.each_key do |card_id|
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.hand_count = 0
        card.count = @cards[card_id]
        @playing_cards << card
      end
    end

    @playing_cards.sort_cards!

    self.hand_count = 0
    self.deck_count = 30

    display_count
    @table_view.reloadData

    if Configuration.show_card_on_hover
      @card_hover.close if @card_hover
    end
  end

  def set_hero(hero_id)
  end

  def draw(card_id)
    self.hand_count += 1

    return if card_id.nil? || card_id.empty?

    card = @playing_cards.select { |c| c.card_id == card_id && c.count > 0 }.first
    return if card.nil?

    card.count -= 1
    card.hand_count += 1
    card.has_changed = true

    self.deck_count -= 1 unless self.deck_count.zero?

    display_count

    @table_view.reloadData
  end

  def deck_discard(card_id)
    return if card_id.nil? || card_id.empty?

    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card_is_discarded = true

      if card_id == 'GVG_035' # Malorne
        if card.count == 0
          # Malorne return to deck
          card_is_discarded = false
          card.count += 1
          self.deck_count += 1
        end
      end

      if card_is_discarded
        card.count -= 1
        card.has_changed = true
        self.deck_count -= 1 unless self.deck_count.zero?
      end
    end

    display_count

    @table_view.reloadData
  end

  def hand_discard(card_id)
    play(card_id)
  end

  def play(card_id)
    self.hand_count -= 1

    card = @playing_cards.select { |c| c.card_id == card_id }.first
    unless card.nil?
      card.hand_count -= 1

      if card.hand_count.zero? && card.count.zero? && Configuration.card_played == :remove
        @playing_cards.delete card
      end
    end

    display_count
    @table_view.reloadData
  end

  def mulligan(card_id)
    self.hand_count -= 1

    return if card_id.nil? || card_id.empty?

    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card.count += 1
      card.hand_count -= 1
    end
    self.deck_count += 1

    display_count
    @table_view.reloadData
  end

  def play_to_deck(card_id)
    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if !card.nil?
      card.count += 1
    else
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.hand_count = 0
        card.count = 1
        card.has_changed = true
        @playing_cards << card
      end

      @playing_cards.sort_cards!
    end

    self.deck_count += 1

    display_count
    @table_view.reloadData
  end

  def get_to_deck(card_id)
    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card.count += 1
      card.has_changed = true
    else
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.hand_count = 0
        card.count = 1
        card.has_changed = true
        card.is_stolen = true
        @playing_cards << card
      end

      @playing_cards.sort_cards!
    end

    self.deck_count += 1
    display_count
    @table_view.reloadData
  end

  def get(card_id, from_play, turn)
    if card_id == 'GAME_005' && turn == 0
      self.hand_count += 1
      return
    end

    log(:tracker, "get from_play : #{from_play}")
    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card.hand_count += 1
    elsif !from_play && Configuration.show_get_cards
      real_card = Card.by_id(card_id)
      if real_card
        card = PlayCard.from_card(real_card)
        card.hand_count = 1
        card.count = 0
        card.has_changed = true
        card.is_stolen = true
        @playing_cards << card
      end

      @playing_cards.sort_cards!
    end
    self.hand_count += 1

    display_count
    @table_view.reloadData
  end

  def joust(card_id)
    #card = @playing_cards.select { |c| c.card_id == card_id }.first
    log :player_tracker, player_joust: card_id
  end

  def deck_to_play(card_id)
    log :player_tracker, deck_to_play: card_id
  end

  def remove_from_deck(card_id)
    log :player_tracker, remove_from_deck: card_id
  end

  def display_count
    text = :hand._(count: self.hand_count)
    text << ' / '
    text << :deck._(count: self.deck_count)
    text << "\n"

    card_count = @playing_cards.map(&:count).inject(0, :+)
    if card_count > 0
      percent = (1 * 100.0) / card_count
      text << ("[1] : #{percent.round(2)}%")
      text << ' / '
      percent = (2 * 100.0) / card_count
      text << ("[2] : #{percent.round(2)}%")
    end

    if Configuration.hand_count_window == :tracker
      @count_text = text
    elsif Configuration.hand_count_window == :window
      @count_window.text = text
    end
  end

  def tableView(tableView, heightOfRow: row)
    if Configuration.hand_count_window == :tracker && row >= @playing_cards.count
      case Configuration.card_layout
        when :small
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
        when :medium
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
        else
          ratio = 1.0
      end
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

  def window_transparency
    @table_view.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end

  # window
  def showWindow(sender)
    super.tap do
      @color_changed = NSNotificationCenter.defaultCenter.observe 'flash_color' do |_|
        @table_view.reloadData if @table_view
      end
    end
  end

  def windowWillClose(_)
    super.tap do
      NSNotificationCenter.defaultCenter.unobserve(@color_changed)
    end
  end

  def hand_count_window_changed
    if @count_window
      @count_window.window.orderOut(self)
      @count_window = nil
    end

    if Configuration.hand_count_window == :window
      @count_window = CardCountHud.alloc.initWithPlayer(:player)
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
    frame = SizeHelper.player_tracker_frame
    return if frame.nil?
    self.window.setFrame(frame, display: true)
  end

end
