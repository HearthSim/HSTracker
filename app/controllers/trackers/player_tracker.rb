# The player tracker window
class PlayerTracker < Tracker

  Log = Motion::Log

  attr_accessor :cards

  # accessors used by card count
  attr_accessor :deck_count, :hand_count

  def init
    super.tap do
      @layout              = PlayerTrackerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @cards         = {}
      @playing_cards = []
      @count_text    = ''

      self.hand_count = 0
      self.deck_count = 30

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate   = self
      @table_view.dataSource = self
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
    @cells         = {}
    @cards         = {}
    @playing_cards = []
    cards.each do |card|
      @cards[card.card_id] = card.count
      @playing_cards << PlayCard.from_card(card)
    end

    @table_view.reloadData
  end

  ## table datasource
  def numberOfRowsInTableView(_)
    @playing_cards.count + 1
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    card = @playing_cards[row]

    if card
      @cells ||= {}
      cell   = @cells[card.card_id] if @cells[card.card_id]

      cell          ||= CardCellView.new
      cell.card     = card
      cell.side     = :player
      cell.delegate = self

      if card.has_changed
        card.has_changed = false
        cell.flash
      end

      @cells[card.card_id] = cell
    else
      cell      = CountTextCellView.new
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
    Log.verbose 'Player reset card'
    reset
  end

  def reset
    @count_text = nil
    @playing_cards = []

    @cards.each_key do |card_id|
      real_card = Card.by_id(card_id)
      if real_card
        card            = PlayCard.from_card(real_card)
        card.hand_count = 0
        card.count      = @cards[card_id]
        @playing_cards << card
      end
    end

    @playing_cards.sort_cards!

    self.hand_count = 0
    self.deck_count = 30

    display_count
    @table_view.reloadData
  end

  def set_hero(hero_id)
    # todo warn if the player don't match with the current deck ?
  end

  def draw(card_id)
    self.hand_count += 1

    return if card_id.nil? or card_id.empty?

    card = @playing_cards.select { |c| c.card_id == card_id and c.count > 0 }.first
    return if card.nil?

    card.count       -= 1
    card.hand_count  += 1
    card.has_changed = true

    self.deck_count  -= 1 unless self.deck_count.zero?

    display_count

    @table_view.reloadData
  end

  def deck_discard(card_id)
    return if card_id.nil? or card_id.empty?

    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card_is_discarded = true

      if card_id == 'GVG_035' # Malorne
        if card.count == 0
          # Malorne return to deck
          card_is_discarded = false
          card.count        += 1
          self.deck_count   += 1
        end
      end

      if card_is_discarded
        card.count       -= 1
        card.has_changed = true
        self.deck_count  -= 1 unless self.deck_count.zero?
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

      if card.hand_count.zero? and card.count.zero? and Configuration.card_played == :remove
        @playing_cards.delete card
      end
    end

    display_count
    @table_view.reloadData
  end

  def mulligan(card_id)
    self.hand_count -= 1

    return if card_id.nil? or card_id.empty?

    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card.count      += 1
      card.hand_count -= 1
    end
    self.deck_count += 1

    display_count
    @table_view.reloadData
  end

  def play_to_deck(card_id)
    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card.nil?
      card.count += 1
    else
      real_card = Card.by_id(card_id)
      if real_card
        card             = PlayCard.from_card(real_card)
        card.hand_count  = 0
        card.count       = 1
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
      card.count       += 1
      card.has_changed = true
    else
      real_card = Card.by_id(card_id)
      if real_card
        card             = PlayCard.from_card(real_card)
        card.hand_count  = 0
        card.count       = 1
        card.has_changed = true
        card.is_stolen   = true
        @playing_cards << card
      end

      @playing_cards.sort_cards!
    end

    self.deck_count += 1
    display_count
    @table_view.reloadData
  end

  def get(card_id, from_play, turn)
    if card_id == 'GAME_005' and turn == 0
      self.hand_count += 1
      return
    end

    card = @playing_cards.select { |c| c.card_id == card_id }.first
    if card
      card.hand_count += 1
    elsif !from_play
      real_card = Card.by_id(card_id)
      if real_card
        card             = PlayCard.from_card(real_card)
        card.hand_count  = 1
        card.count       = 0
        card.has_changed = true
        card.is_stolen   = true
        @playing_cards << card
      end

      @playing_cards.sort_cards!
    end
    self.hand_count += 1

    display_count
    @table_view.reloadData
  end

  def display_count
    text = ("#{'Hand : '._} #{self.hand_count}")
    text << ' / '
    text << ("#{'Deck : '._} #{self.deck_count}")

    @count_text = text
  end

  def window_transparency
    @table_view.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end

  # card hover
  def hover(cell)
    card_count = @playing_cards.map(&:count).inject(0, :+)
    card       = cell.card

    percent     = (card.count * 100.0) / card_count
    @count_text = "#{'Draw : '._}#{percent.round(2)}%"
    @table_view.reloadDataForRowIndexes([@playing_cards.count].nsindexset,
                                        columnIndexes: [0].nsindexset)
  end

  def out(_)
    display_count
    @table_view.reloadDataForRowIndexes([@playing_cards.count].nsindexset,
                                        columnIndexes: [0].nsindexset)
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

end
