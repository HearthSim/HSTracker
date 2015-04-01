# The player tracker window
class PlayerTracker < Tracker

  Log = Motion::Log

  attr_accessor :cards

  # accessors used by Configuration.one_line_count == :on_trackers
  attr_accessor :deck_count, :hand_count, :has_coin

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

  def init
    super.tap do
      @layout              = PlayerTrackerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @cards         = {}
      @playing_cards = []
      @count_text    = ''

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate   = self
      @table_view.dataSource = self

      @card_hover = CardHover.new
      @card_hover.showWindow(self.window)
    end
  end

  ## table datasource
  def numberOfRowsInTableView(_)
    count = @playing_cards.count
    if Configuration.one_line_count == :on_trackers
      count += 1
    end

    count
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
    Log.verbose 'Player reset card'
    @playing_cards.each do |card|
      card.count      = @cards[card.card_id]
      card.hand_count = 0
    end

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
    if Configuration.one_line_count == :on_trackers
      text = ("#{'Hand : '._} #{self.hand_count}")
      text << ' / '
      text << ("#{'Deck : '._} #{self.deck_count}")

      @count_text = text
    end
  end

  def window_transparency
    @table_view.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end

  # card hover
  def hover(cell)
    card_count = @playing_cards.map(&:count).inject(0, :+)
    card       = cell.card

    @card_hover.show_stats(card.count, card_count)
  end

  def out(_)
    @card_hover.clear
  end

  # window
  def showWindow(sender)
    super.tap do
      @color_changed = NSNotificationCenter.defaultCenter.observe 'flash_color' do |notification|
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
