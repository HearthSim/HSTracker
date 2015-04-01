# The opponent tracker window
class OpponentTracker < Tracker

  # accessors used by Configuration.one_line_count == :on_trackers
  attr_accessor :deck_count, :hand_count, :has_coin

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
    count = @cards.count
    if Configuration.one_line_count == :on_trackers
      count += 1
    end

    count
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
    elsif Configuration.one_line_count == :on_trackers
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
    @table_view.reloadData
    unless Configuration.fixed_window_names
      self.window.title = 'HSTracker'
    end

    self.has_coin   = false
    self.hand_count = 0
    self.deck_count = 30
    display_count
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
  end

  def play_secret
    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
  end

  def card_stolen(_)
    self.hand_count += 1
    display_count
  end

  def discard_card(card_id)
    # card discarded, consider he played the card
    play_card(card_id)

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
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
      card            = PlayCard.from_card(Card.by_id(card_id))
      card.count      = 1
      card.hand_count = 0
      @cards << card
      @cards = Sorter.sort_cards @cards
    end

    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
  end

  def restore_card(_)
    self.deck_count += 1
    self.hand_count -= 1 unless self.hand_count.zero?
    display_count
  end

  def get_coin(_)
    # increment deck_count by 1 because we decrement it when the
    # coin has been drawned
    self.has_coin   = true
    self.deck_count += 1
    display_count
  end

  def display_count
    if Configuration.one_line_count == :on_trackers
      text = ("#{'Hand : '._} #{self.hand_count}")
      text << ' / '
      text << ("#{'Deck : '._} #{self.deck_count}")

      @count_text = text

      @table_view.reloadData
    end
  end

  def window_transparency
    @table_view.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end

end
