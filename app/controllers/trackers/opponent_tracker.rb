# The opponent tracker window
class OpponentTracker < Tracker

  Log = Motion::Log

  def init
    super.tap do
      @layout              = OpponentTrackerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @cards = []

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate   = self
      @table_view.dataSource = self
    end
  end

  ## table datasource
  def numberOfRowsInTableView(_)
    @cards.count
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    card = @cards[row]

    @cells ||= {}
    cell   = @cells[card.card_id] if @cells[card.card_id]

    cell                 ||= CardCellView.new
    cell.card            = card
    cell.side            = :opponent
    @cells[card.card_id] = cell

    cell
  end

  # disable selection
  def selectionShouldChangeInTableView(tableView)
    false
  end

  # game events
  def game_start
    Log.verbose 'Opponent reset card'
    @cards = []
    @table_view.reloadData
    self.window.title = 'HSTracker'
  end

  def set_hero(player, hero_id)
    return if player == :player

    hero = Card.hero(hero_id)
    if hero
      self.window.setTitle hero.player_class._
    end
  end

  def discard_card(card_id)
    # for the opponent, consider he played the card
    play_card(card_id)
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
    @table_view.reloadData
  end

  def window_transparency
    @table_view.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end

end
