class DeckManager < NSWindowController
  include CDQ

  KMaxCardOccurence = {
      :arena       => 30,
      :constructed => 2
  }

  KClasses = %w(Shaman Hunter Warlock Druid Warrior Mage Paladin Priest Rogue Neutral)

  attr_accessor :player_view

  Log = Motion::Log

  def init
    super.tap do
      @layout              = DeckManagerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @saved             = true
      @in_edition        = false
      @max_cards_in_deck = 30

      # preparation for arena
      @current_deck_mode = :constructed

      # load decks
      show_decks

      # init tabs
      @tabs = @layout.get(:tabs)
      @tabs.setAction 'tab_changed:'
      @tabs.setTarget self
      @tabs.setSegmentCount KClasses.size

      KClasses.each_with_index do |clazz, idx|
        @tabs.setLabel(clazz._, forSegment: idx)
      end

      @tabs.setSelected(true, forSegment: 0)
      @current_class = KClasses[0]

      # init table
      @table_view    = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.doubleAction = 'double_click:'
      @table_view.delegate     = self
      @table_view.dataSource   = self

      # init card view
      @cards_view              = @layout.get(:cards_view)
      @cards_view.dataSource   = self
      @cards_view.delegate     = self

      grid_layout                      = JNWCollectionViewGridLayout.alloc.initWithCollectionView(@cards_view)
      grid_layout.delegate             = self
      grid_layout.itemSize             = [191, 260]
      @cards_view.collectionViewLayout = grid_layout
      @cards_view.registerClass(CardItemView, forCellWithReuseIdentifier: 'card_item')

      @cards = nil
      @cards_view.reloadData

      @left = @layout.get(:left)

      @toolbar             = NSToolbar.alloc.initWithIdentifier 'toolbar'
      @toolbar.displayMode = NSToolbarDisplayModeIconOnly
      @toolbar.delegate    = self
      self.window.toolbar  = @toolbar

      check_clipboad_net_deck

      @card_count = @layout.get(:card_count)
    end
  end

  def check_is_saved_on_close
    close = @saved

    unless @saved
      response = NSAlert.alert('Delete'._,
                               :buttons     => ['OK'._, 'Cancel'._],
                               :informative => 'Are you sure you want to close this deck ? Your changes will not be saved.'._
      )

      if response == NSAlertFirstButtonReturn
        close = true
      end
    end
    close
  end

  def show_decks
    @decks_or_cards = []
    Deck.all.sort_by(:name, :case_insensitive => true).each do |deck|
      @decks_or_cards << deck
    end

    KClasses.each_with_index do |_, index|
      @tabs.setEnabled(true, forSegment: index)
    end if @tabs
  end

  def cards
    @cards ||= begin
      clazz = @current_class
      if @current_class == 'Neutral'
        clazz = nil
      end
      Card.per_lang.playable
          .where(:player_class => clazz)
          .sort_by(:cost)
          .sort_by(:name)
    end
  end

  # JNWCollection stuff
  def collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    cell          = @cards_view.dequeueReusableCellWithIdentifier('card_item')
    card          = cards[indexPath.jnw_item]
    cell.delegate = self
    cell.card     = card

    cell
  end

  def numberOfSections
    1
  end

  def collectionView(collectionView, numberOfItemsInSection: section)
    return cards.count if cards
    0
  end

  def collectionView(collectionView, mouseUpInItemAtIndexPath: indexPath)
    return unless @in_edition
    card_count = @decks_or_cards.count_cards
    return if card_count >= @max_cards_in_deck

    @card_count.stringValue = "#{card_count + 1} / #{@max_cards_in_deck}"

    cell = collectionView.cellForItemAtIndexPath(indexPath)
    c    = cell.card

    found = false
    @decks_or_cards.each do |card|
      if card.card_id == c.card_id
        card.hand_count = 0

        if card.count + 1 > KMaxCardOccurence[@current_deck_mode] or card.rarity == 'Legendary'._
          return
        end

        card.count += 1
        found      = true
      end
    end

    unless found
      @decks_or_cards << c
      @decks_or_cards.sort_cards!
    end
    @table_view.reloadData
    @saved = false
  end

  # CardItemView delegate
  def hover(cell)
    rect          = self.window.contentView.convertRect(cell.bounds, fromView: cell)
    point         = rect.origin
    point.x       += CGRectGetWidth(cell.frame) + 130
    point.y       += 100
    @tooltip      ||= Tooltip.new
    @tooltip.card = cell.card
    rect          = [point, [250, @tooltip.text_height + 20]]

    @tooltip.window.setFrame(rect, display: true)
    self.window.addChildWindow(@tooltip.window, ordered: NSWindowAbove)
  end

  def out(_)
    @tooltip.window.orderOut(self) if @tooltip
  end

  # nssegmentedcontrol
  def tab_changed(_)
    @current_class = KClasses[@tabs.selectedSegment]
    @cards         = nil

    @cards_view.reloadData
  end

  # tables stuff
  def numberOfRowsInTableView(tableView)
    return @decks_or_cards.count if @decks_or_cards
    0
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    deck_or_card = @decks_or_cards[row]

    if deck_or_card.is_a? Card
      cell      = CardCellView.new
      cell.card_size = :big
      cell.side = :opponent
      cell.card = deck_or_card
    else
      cell      = DeckCellView.new
      cell.deck = deck_or_card
    end

    cell
  end

  # disable selection
  def selectionShouldChangeInTableView(tableView)
    false
  end

  def double_click(cell)
    deck_or_card = @decks_or_cards[@table_view.clickedRow]

    if deck_or_card.is_a? Deck
      show_deck(deck_or_card)
    else
      if deck_or_card.count == 1
        @decks_or_cards.delete(deck_or_card)
      else
        deck_or_card.count -= 1
      end

      card_count              = @decks_or_cards.count_cards
      @card_count.stringValue = "#{card_count} / #{@max_cards_in_deck}"

      @saved = false
      @table_view.reloadData
    end
  end

  # toolbar stuff
  # enable / disable items
  def validateToolbarItem(item)
    case item.itemIdentifier
      when 'save', 'delete', 'close', 'play', 'export'
        @in_edition
      when 'new', 'import', 'arena'
        !@in_edition
      else
        true
    end
  end

  def toolbarAllowedItemIdentifiers(toolbar)
    ['new', 'arena', 'import', 'save', 'search', 'close', 'delete', 'play', 'export', 'donate',
     NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier]
  end

  def toolbarDefaultItemIdentifiers(toolbar)
    ['new', 'arena', 'import', NSToolbarSeparatorItemIdentifier,
     'save', 'delete', 'close', 'play', 'export',
     NSToolbarFlexibleSpaceItemIdentifier, 'search', 'donate']
  end

  def toolbar(toolbar, itemForItemIdentifier: identifier, willBeInsertedIntoToolbar: flag)
    item = NSToolbarItem.alloc.initWithItemIdentifier(identifier)
    case identifier
      when 'import'
        item.label   = 'Import'._
        item.toolTip = 'Import'._
        image        = 'import'.nsimage
        image.setTemplate true
        item.image  = image
        item.target = self
        item.action = 'import_deck:'

      when 'new', 'arena'
        label  = (identifier == 'new') ? 'New'._ : 'Arena Deck'._
        action = (identifier == 'new') ? 'add_deck:' : 'add_area_deck:'

        item.label = label

        menu      = NSMenu.alloc.initWithTitle identifier
        menu_item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
        menu.addItem menu_item

        classes = KClasses[0...-1]
        classes.each do |clazz|
          menu_item            = NSMenuItem.alloc.initWithTitle(clazz._, action: action, keyEquivalent: '')
          menu_item.identifier = clazz
          menu.addItem menu_item
        end
        popup           = NSPopUpButton.alloc.initWithFrame [[0, 0], [100, 22]]
        popup.bordered  = false
        popup.pullsDown = true
        popup.menu      = menu
        item.view       = popup

      when 'close'
        item.label   = 'Close'._
        item.toolTip = 'Close'._
        image        = 'close'.nsimage
        image.setTemplate true
        item.image  = image
        item.target = self
        item.action = 'close_deck:'

      when 'save'
        item.label   = 'Save'._
        item.toolTip = 'Save'._
        image        = 'save'.nsimage
        image.setTemplate true
        item.image  = image
        item.target = self
        item.action = 'save_deck:'

      when 'export'
        item.label   = 'Export'._
        item.toolTip = 'Export'._
        image        = 'export'.nsimage
        image.setTemplate true
        item.image  = image
        item.target = self
        item.action = 'export_deck:'

      when 'play'
        item.label   = 'Play'._
        item.toolTip = 'Play'._
        image        = 'play'.nsimage
        image.setTemplate true
        item.image  = image
        item.target = self
        item.action = 'play_deck:'

      when 'delete'
        item.label   = 'Delete'._
        item.toolTip = 'Delete'._
        image        = 'delete'.nsimage
        image.setTemplate true
        item.image  = image
        item.target = self
        item.action = 'delete_deck:'

      when 'donate'
        item.label   = 'Donate'._
        item.toolTip = 'Donate'._
        image        = 'donate'.nsimage
        item.image  = image
        item.target = self
        item.action = 'donate:'

      when 'search'
        item.label                        = 'Search'
        view                              = NSSearchField.alloc.initWithFrame(NSZeroRect)
        view.target                       = self
        view.action                       = 'search:'
        view.cell.cancelButtonCell.target = self
        view.cell.cancelButtonCell.action = 'cancel_search:'
        view.frame                        = [[0, 0], [200, 0]]
        item.view                         = view
    end
    item
  end

  # actions
  def import_deck(_)
    if @in_edition and !@saved
      NSAlert.alert('Error'._,
                    :buttons     => ['OK'._],
                    :informative => 'You are currently in a deck edition and you changes have not been saved.'._,
                    :style       => NSCriticalAlertStyle,
                    :window      => self.window,
                    :delegate    => self
      )
      return
    end

    @import = DeckImport.alloc.init
    @import.on_deck_loaded do |cards, clazz, name, arena|
      Log.debug "#{clazz} / #{name} / #{arena}"

      if cards
        @saved = false
        show_deck(cards, clazz, name, arena)
      end
    end
    self.window.beginSheet(@import.window, completionHandler: nil)
  end

  def play_deck(_)
    unless @saved
      response = NSAlert.alert('Play'._,
                               :buttons     => ['OK'._, 'Cancel'._],
                               :informative => 'Your deck is not saved, are you sure you want to continue, you will lose all changes.'._,
                               :style       => NSInformationalAlertStyle
      )

      if response == NSAlertSecondButtonReturn
        return
      end
    end

    player_view.show_deck(@decks_or_cards, @deck_name) if player_view
  end

  def show_deck(deck, clazz=nil, name=nil, arena=false)
    @in_edition = true

    if deck.is_a? Deck
      @current_deck = deck

      @current_deck.arena ? @current_deck_mode = :arena : @current_deck_mode = :constructed
      @decks_or_cards = @current_deck.playable_cards
      @deck_name      = deck.name
      @deck_class     = deck.player_class
    else
      arena ? @current_deck_mode = :arena : @current_deck_mode = :constructed
      @current_deck   = nil
      @decks_or_cards = deck
      @deck_name      = name
      @deck_class     = clazz
    end
    @current_class = @deck_class

    selected_class = KClasses.index(@current_class)
    KClasses.each_with_index do |claz, index|
      enabled = selected_class == index || claz == 'Neutral'
      @tabs.setEnabled(enabled, forSegment: index)
      @tabs.setSelected(selected_class == index, forSegment: index)
    end
    @cards = nil

    card_count              = @decks_or_cards.count_cards
    @card_count.stringValue = "#{card_count} / #{@max_cards_in_deck}"

    @cards_view.reloadData
    @table_view.reloadData
  end

  def add_area_deck(sender)
    @current_deck_mode = :arena
    start_new_deck(sender)
  end

  def add_deck(sender)
    @current_deck_mode = :constructed
    start_new_deck(sender)
  end

  def start_new_deck(sender)
    clazz = sender.identifier

    @in_edition     = true
    @saved          = false
    @deck_class     = clazz.sub(/^(\w)/) { |s| s.capitalize }
    @current_class  = @deck_class
    @decks_or_cards = []

    @card_count.stringValue = "0 / #{@max_cards_in_deck}"

    selected_class = KClasses.index(@current_class)
    KClasses.each_with_index do |claz, index|
      enabled = selected_class == index || claz == 'Neutral'
      @tabs.setEnabled(enabled, forSegment: index)
      @tabs.setSelected(selected_class == index, forSegment: index)
    end
    @cards = nil

    @cards_view.reloadData
    @table_view.reloadData
  end

  def delete_deck(_)
    response = NSAlert.alert('Delete'._,
                             :buttons     => ['OK'._, 'Cancel'._],
                             :informative => 'Are you sure you want to delete this deck ?'._
    )

    if response == NSAlertFirstButtonReturn
      @current_deck.destroy

      cdq.save

      @current_deck = nil
      @deck_name    = nil
      @deck_class   = nil
      @in_edition = false
      @saved      = true
      show_decks

      NSNotificationCenter.defaultCenter.post('deck_change')
      @card_count.stringValue = ""
      @table_view.reloadData
    end
  end

  def save_deck(_)
    card_count = @decks_or_cards.count_cards

    if card_count < @max_cards_in_deck
      response = NSAlert.alert('Save'._,
                               :buttons     => ['OK'._, 'Cancel'._],
                               :informative => "Your deck don't have 30 cards, are you sure you want to continue ?"._
      )

      if response == NSAlertFirstButtonReturn
        return
      end
    end

    deck_name_input = NSTextField.alloc.initWithFrame [[0, 0], [220, 24]]
    if @deck_name
      deck_name_input.stringValue = @deck_name
    end

    response = NSAlert.alert('Deck name'._,
                             :buttons => ['OK'._, 'Cancel'._],
                             :view    => deck_name_input
    )

    if response == NSAlertSecondButtonReturn
      return
    end

    deck_name_input.validateEditing
    deck_name = deck_name_input.stringValue

    if @current_deck.nil?
      @current_deck = Deck.create(:player_class => @deck_class)
    end

    @current_deck.arena = @current_deck_mode == :arena
    @current_deck.name  = deck_name

    @current_deck.cards.each do |c|
      c.destroy
    end

    @decks_or_cards.each do |card|
      @current_deck.cards.create(:card_id => card.card_id, :count => card.count)
    end

    cdq.save

    @saved = true
    NSNotificationCenter.defaultCenter.post('deck_change')

    NSAlert.alert('Save'._,
                  :buttons     => ['OK'._],
                  :informative => 'Deck saved'._,
                  :style       => NSInformationalAlertStyle
    )
  end

  def close_deck(_)
    close = @saved

    unless @saved
      response = NSAlert.alert('Close'._,
                               :buttons     => ['OK'._, 'Cancel'._],
                               :informative => 'Are you sure you want to close this deck ? Your changes will not be saved.'._
      )

      if response == NSAlertFirstButtonReturn
        close = true
      end
    end

    if close
      @in_edition   = false
      @saved        = true
      @current_deck = nil
      @deck_name    = nil
      @deck_class   = nil
      show_decks
      @card_count.stringValue = ""
      @table_view.reloadData
    end
  end

  def search(sender)
    str = sender.stringValue

    class_name = @current_class == 'Neutral' ? nil : @current_class

    @cards = Card.per_lang.playable
                 .and(
                     cdq(:name).contains(str, NSCaseInsensitivePredicateOption)
                         .or(:text).contains(str, NSCaseInsensitivePredicateOption)
                         .or(:rarity).contains(str, NSCaseInsensitivePredicateOption)
                         .or(:card_type).contains(str, NSCaseInsensitivePredicateOption)
                 ).and(:player_class).eq(class_name)
                 .sort_by(:cost)
                 .sort_by(:name)
    @cards_view.reloadData
  end

  def export_deck(_)
    panel                      = NSSavePanel.savePanel
    panel.allowedFileTypes     = %w(txt)
    panel.canCreateDirectories = true
    panel.nameFieldStringValue = "#{@deck_name}.txt"
    panel.title                = 'Export Deck'._

    result = panel.runModal
    if result == NSOKButton
      path = panel.URL.path

      content = []
      @decks_or_cards.each do |card|
        (0...card.count).each do
          content << card.name
        end
      end

      content.sort.join("\n").nsdata.write_to(path)
    end
  end

  def cancel_search(sender)
    sender.stringValue = ''
    sender.resignFirstResponder
    @cards = nil
    @cards_view.reloadData
  end

  def check_clipboad_net_deck
    Importer.netdeck do |deck, clazz, name, arena|
      unless @in_edition
        @saved = false
        show_deck(deck, clazz, name, arena)
      end
    end
  end

  def donate(_)
    NSWorkspace.sharedWorkspace.openURL 'https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=bmichotte%40gmail%2ecom&lc=US&item_name=HSTracker&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted'.nsurl
  end

end