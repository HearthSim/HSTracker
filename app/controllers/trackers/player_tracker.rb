# The player tracker window
class PlayerTracker < Tracker

  Log = Motion::Log

  attr_accessor :cards

  # accessors used by card count
  attr_accessor :deck_count, :hand_count, :has_coin

  def init
    super.tap do
      @layout              = PlayerTrackerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @cards         = {}
      @playing_cards = []
      @count_text    = ''

      self.has_coin   = false
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
  def game_end(_)
    if Configuration.reset_on_end
      @count_text = nil
      game_start
    end
  end

  def game_start
    Log.verbose 'Player reset card'
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

    self.has_coin   = false
    self.hand_count = 0
    self.deck_count = 30
    display_count

    @table_view.reloadData
  end

  def set_hero(player, hero_id)
    return if player == :opponent
    # todo warn if the player don't match with the current deck ?
  end

  def draw_card(card_id)
    @playing_cards.each do |card|
      if card.card_id == card_id
        card.hand_count  += 1
        card.count       -= 1 unless card.count.zero?
        card.has_changed = true

        Log.verbose "******** draw #{card.name} -> count : #{card.count}, hand : #{card.hand_count}"
      end
    end

    self.hand_count += 1
    self.deck_count -= 1 unless self.deck_count.zero?
    display_count

    @table_view.reloadData
  end

  def copy_card(card_id)
    found = false
    Log.verbose "******** copy #{card.name}"
    @playing_cards.each do |card|
      if card.card_id == card_id
        card.count       += 1
        card.has_changed = true
        found            = true
      end
    end

    unless found
      real_card = Card.by_id(card_id)
      if real_card
        card             = PlayCard.from_card(real_card)
        card.hand_count  = 0
        card.count       = 1
        card.has_changed = true
        card.in_deck     = true
        @playing_cards << card
      end

      @playing_cards.sort_cards!
    end

    self.deck_count += 1
    display_count
    @table_view.reloadData
  end

  def play_secret
    self.hand_count -= 1 unless self.hand_count.zero?
    display_count

    @table_view.reloadData
  end

  def card_stolen(_)
    self.hand_count += 1
    display_count

    @table_view.reloadData
  end

  def discard_card(card_id)
    # card discarded, consider we played the card
    play_card(card_id)

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count

    @table_view.reloadData
  end

  def play_card(card_id)
    @playing_cards.each do |card|
      if card.card_id == card_id
        card.hand_count -= 1 unless card.hand_count.zero?
        Log.verbose "******** play #{card.name} -> count : #{card.count}, hand : #{card.hand_count}"

        if card.hand_count.zero? and card.count.zero? and Configuration.card_played == :remove
          @playing_cards.delete card
        end
      end
    end

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count

    @table_view.reloadData
  end

  def restore_card(card_id)
    @playing_cards.each do |card|
      if card.card_id == card_id
        card.count      += 1
        card.hand_count -= 1 unless card.hand_count.zero?

        Log.verbose "******** restore #{card.name} -> count : #{card.count}, hand : #{card.hand_count}"
      end
    end

    self.deck_count += 1
    self.hand_count -= 1 unless self.hand_count.zero?
    display_count

    @table_view.reloadData
  end

  def get_coin(_)
    # increment deck_count by 1 because we decrement it when the
    # coin has been drawned
    self.has_coin   = true
    self.deck_count += 1
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
