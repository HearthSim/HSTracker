# The player tracker window
class PlayerTracker < NSWindowController

  Log = Motion::Log

  attr_accessor :cards

  def cards=(cards)
    @cells = {}
    @cards = {}
    cards.each do |card|
      @cards[card.card_id] = card.count
    end
    @playing_cards = cards

    @table_view.reloadData
  end

  def init
    super.tap do
      @layout              = PlayerTrackerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @cards         = {}
      @playing_cards = []

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
    @playing_cards.count
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    card = @playing_cards[row]

    @cells ||= {}
    cell   = @cells[card.card_id] if @cells[card.card_id]

    cell                 ||= CardCellView.new
    cell.card            = card
    cell.side            = :player
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
    Log.verbose 'Player reset card'
    @playing_cards.each do |card|
      card.count      = @cards[card.card_id]
      card.hand_count = 0
    end

    Dispatch::Queue.main.after(1) do
      @table_view.beginUpdates
      @table_view.reloadData
      @table_view.endUpdates
    end
  end

  def set_hero(player, hero_id)
    return if player == :opponent
    # todo warn if the player don't match with the current deck ?
  end

  def draw_card(card_id)
    @playing_cards.each do |card|
      if card.card_id == card_id
        card.hand_count += 1
        card.count      -= 1 unless card.count.zero?

        Log.verbose "******** draw #{card.name} -> count : #{card.count}, hand : #{card.hand_count}"
      end
    end
    @table_view.reloadData
  end

  def play_card(card_id)
    @playing_cards.each do |card|
      if card.card_id == card_id
        card.hand_count -= 1 unless card.hand_count.zero?
        Log.verbose "******** play #{card.name} -> count : #{card.count}, hand : #{card.hand_count}"
      end
    end
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
    @table_view.reloadData
  end

end
