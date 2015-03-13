# The opponent tracker window
class OpponentTracker < NSWindowController

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

  def windowWillMiniaturize(_)
    window.setLevel(NSNormalWindowLevel)
  end

  def windowDidMiniaturize(_)
    window.setLevel(NSScreenSaverWindowLevel)
  end

=begin
      #window.styleMask = NSBorderlessWindowMask

  def canBecomeKeyWindow
    true
  end

  def canBecomeMainWindow
    true
  end
=end

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
    #cell.delegate = self
    @cells[card.card_id] = cell

    cell
  end

  # disable selection
  def selectionShouldChangeInTableView(tableView)
    false
  end

  # game events
  def reset_cards
    Log.verbose 'Opponent reset card'
    @cards = []
    @table_view.reloadData
    self.window.setTitle 'HSTracker'
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
      @cards << Card.by_id(card_id)
      @cards = Sorter.sort_deck @cards
    end
    @table_view.reloadData
  end

end
