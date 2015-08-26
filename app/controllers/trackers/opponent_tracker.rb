# The opponent tracker window
class OpponentTracker < Tracker

  # accessors used by card count
  attr_accessor :deck_count, :hand_count, :cards, :count_window, :card_huds

  CoinPosition = 4

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

      self.card_huds = (0..10).map do |position|
        card_hud = OpponentCardHud.alloc.initWithPosition(position)
        card_hud.showWindow(self)
        card_hud
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
    self.card_huds.each do |card_hud|
      card_hud.text = nil
    end

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
    @ages = {}
    @marks = {}

    unless Configuration.fixed_window_names
      self.window.title = 'HSTracker'
    end

    self.hand_count = 0
    self.deck_count = 30
    display_count
    @table_view.reloadData

    if Configuration.show_card_on_hover
      @card_hover.close if @card_hover
    end

    (0..10).each do |i|
      @ages[i] = -1
      @marks[i] = :none
    end

    reload_card_huds
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
      @ages[CoinPosition] = turn
      @marks[CoinPosition] = :coin
    else
      self.deck_count -= 1 unless self.deck_count.zero?
      @ages[self.hand_count - 1] = turn
      @marks[self.hand_count - 1] = turn.zero? ? :kept : :none
    end

    display_count
    @table_view.reloadData
    reload_card_huds
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

    reload_card_huds
  end

  def play(card_id, from, turn)
    #wasReturnedToDeck = OpponentReturnedToDeck.Any(p => p.Key == id && p.Value <= OpponentHandAge[from - 1]);
    wasReturnedToDeck = false
    stolen = from != -1 && (@marks[from - 1] == :stolen || @marks[from - 1] == :returned || wasReturnedToDeck)

    # card can't be marked stolen or returned, since it was returned to the deck
    if wasReturnedToDeck && stolen && !(@marks[from - 1] == :stolen || @marks[from - 1] == :returned)
      #OpponentReturnedToDeck.Remove(OpponentReturnedToDeck.First(p => p.Key == id && p.Value <= OpponentHandAge[from - 1]));
    end

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

    ((from - 1)..9).each do |i|
      @ages[i] = @ages[i + 1]
      @marks[i] = @marks[i + 1]
      #OpponentStolenCardsInformation[i] = OpponentStolenCardsInformation[i + 1];
    end

    @ages[9] = -1
    @marks[9] = :none
    #OpponentStolenCardsInformation[MaxHandSize - 1] = null;

    reload_card_huds
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

  def mulligan(pos)
    self.hand_count -= 1
    self.deck_count += 1

    display_count
    @table_view.reloadData

    @marks[pos - 1] = :mulliganed

    reload_card_huds
  end

  def play_to_hand(card_id, turn, id)
    self.hand_count -= 1
    card = @cards.select { |c| c.card_id == card_id }.first
    if card
      card.count -= 1
    end

    display_count
    @table_view.reloadData

    @ages[self.hand_count - 1] = turn
    @marks[self.hand_count - 1] = :returned

    reload_card_huds
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

    @ages[self.hand_count - 1] = turn

    if @marks[self.hand_count - 1] != :coin
      @marks[self.hand_count - 1] = :stolen
=begin
      if SecondToLastUsedId.HasValue
        var cardId = Entities[id].CardId
        if cardId == "GVG_007" && Entities[id].HasTag(GAME_TAG.DISPLAYED_CREATOR)
          #Bug with created Flame Leviathan's: #863
          return

          if (string.IsNullOrEmpty(cardId) && Entities[id].HasTag(GAME_TAG.LAST_AFFECTED_BY))
            cardId = Entities[Entities[id].GetTag(GAME_TAG.LAST_AFFECTED_BY)].CardId;
          end
          if (string.IsNullOrEmpty(cardId))
            cardId = Entities[SecondToLastUsedId.Value].CardId;
          end

          var card = GetCardFromId(cardId);
          if (card != null)
            OpponentStolenCardsInformation[OpponentHandCount - 1] = card;
          end
        end
      end
=end
    end

    reload_card_huds
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

  def reload_card_huds
    mp opponent_hand: @ages.map { |k, v| { age: v, card: @marks[k] } }.join(', ')

    self.card_huds.each do |card_hud|
      age = @ages[card_hud.position]
      if age == -1
        card_hud.window.orderOut(self)
        next
      end

      card_hud.window.orderFront(self)
      text = case @marks[card_hud.position]
               when :coin
                 :coin_abbr._
               else
                 age.to_s
             end
      card_hud.text = text
      card_hud.resize_window_with_cards(self.hand_count)
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
    self.card_huds.each do |card_hud|
      card_hud.set_level level
    end
  end

  def resize_window
    frame = SizeHelper.opponent_tracker_frame
    return if frame.nil?
    self.window.setFrame(frame, display: true)

    self.card_huds.each do |card_hud|
      card_hud.resize_window_with_cards(self.hand_count)
    end
  end
end
