# The opponent tracker window
class OpponentTracker < Tracker

  # accessors used by card count
  attr_accessor :deck_count, :hand_count, :has_coin

  def deck_count
    @deck_count ||= 30
  end

  def hand_count
    @hand_count ||= 0
  end

  Log = Motion::Log

  def init
    super.tap do
      @layout              = OpponentTrackerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @cards      = []
      @count_text = ''

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate   = self
      @table_view.dataSource = self
    end
  end

  ## table datasource
  def numberOfRowsInTableView(_)
    @cards.count + 1
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    card = @cards[row]

    if card
      @cells ||= {}
      cell   = @cells[card.card_id] if @cells[card.card_id]

      cell                 ||= CardCellView.new
      cell.card            = card
      cell.side            = :opponent
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
    Log.verbose 'Opponent reset card'
    @cards = []

    unless Configuration.fixed_window_names
      self.window.title = 'HSTracker'
    end

    self.has_coin   = false
    self.hand_count = 0
    self.deck_count = 30
    display_count
    @table_view.reloadData
  end

  def set_hero(player, hero_id)
    return if player == :player

    hero = Card.hero(hero_id)
    if hero and !Configuration.fixed_window_names
      self.window.setTitle hero.player_class._
    end
  end

  def draw_card(_)
    self.hand_count += 1
    self.deck_count -= 1 unless self.deck_count.zero?
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
    # card discarded, consider he played the card
    play_card(card_id)

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
    @table_view.reloadData
  end

  def secret_revealed(card_id)
    # for the opponent, consider he played the card
    play_card(card_id)
  end

  def play_card(card_id)
    found = false
    @cards.each do |card|
      if card.card_id == card_id
        card.hand_count = 0
        card.count      += 1
        found           = true
      end
    end

    unless found
      real_card = Card.by_id(card_id)
      if real_card
        card            = PlayCard.from_card(real_card)
        card.count      = 1
        card.hand_count = 0
        @cards << card
        @cards.sort_cards!
      end
    end

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
    @table_view.reloadData
  end

  def copy_card(card_id)
    found = false

    @cards.each do |card|
      if card.card_id == card_id and card.in_deck
        Log.verbose "******** copy #{card.name}"
        card.count       += 1
        card.has_changed = true
        found            = true
      end
    end

    unless found
      real_card = Card.by_id(card_id)
      if real_card
        card             = PlayCard.from_card(real_card)
        Log.verbose "******** copy #{card.name}"
        card.hand_count  = 0
        card.count       = 1
        card.in_deck     = true
        card.has_changed = true
        @cards << card
      end

      @cards.sort_cards!
    end

    self.deck_count += 1
    display_count
    @table_view.reloadData
  end

  def restore_card(_)
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

end
