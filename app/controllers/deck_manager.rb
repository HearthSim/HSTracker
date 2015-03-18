class DeckManager < NSWindowController
  include CDQ

  KMaxCardOccurence = {
      :arena       => 30,
      :constructed => 2
  }

  attr_accessor :player_view

  Log = Motion::Log

  def init
    super.tap do
      @layout              = DeckManagerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @saved              = true
      @in_edition         = false
      @max_cards_in_deck  = 30

      # preparation for arena
      @current_deck_mode  = :constructed

      show_decks

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.delegate     = self
      @table_view.dataSource   = self
      @table_view.doubleAction = 'double_click:'

      @cards_view                  = JNWCollectionView.alloc.initWithFrame CGRectZero
      @cards_view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable
      @cards_view.dataSource       = self
      @cards_view.delegate         = self
      @cards_view.backgroundColor  = :clear.nscolor
      @cards_view.drawsBackground  = false

      grid_layout                      = JNWCollectionViewGridLayout.alloc.initWithCollectionView(@cards_view)
      grid_layout.delegate             = self
      grid_layout.itemSize             = [191, 260]
      @cards_view.collectionViewLayout = grid_layout

      @cards_view.registerClass(CardItemView, forCellWithReuseIdentifier: 'card_item')

      @tab_view          = @layout.get(:tab_view)
      @tab_view.delegate = self
      @tab_view.selectFirstTabViewItem(self)
      tab_view_item      = @tab_view.tabViewItems.first
      @current_class     = tab_view_item.identifier
      tab_view_item.view = @cards_view
      @cards             = nil
      @cards_view.reloadData

      @left = @layout.get(:left)

      @toolbar             = NSToolbar.alloc.initWithIdentifier 'toolbar'
      @toolbar.displayMode = NSToolbarDisplayModeIconOnly
      @toolbar.delegate    = self
      self.window.toolbar  = @toolbar

      check_clipboad_net_deck
    end
  end

  def check_is_saved_on_close
    close = @saved

    unless @saved
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.addButtonWithTitle('Cancel'._)
      alert.setMessageText('Delete'._)
      alert.setInformativeText('Are you sure you want to close this deck ? Your changes will not be saved.'._)
      alert.setAlertStyle(NSInformationalAlertStyle)
      response = alert.runModal

      if response == NSAlertFirstButtonReturn
        close = true
      end
    end
    close
  end

  def show_decks
    @decks_or_cards = []
    Deck.all.sort_by(:name).each do |deck|
      @decks_or_cards << deck
    end
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
    cards.count
  end

  def collectionView(collectionView, mouseUpInItemAtIndexPath: indexPath)
    return unless @in_edition
    card_count = @decks_or_cards.map(&:count).inject(0, :+)
    return if card_count >= @max_cards_in_deck

    cell = collectionView.cellForItemAtIndexPath(indexPath)
    c    = cell.card

    found = false
    @decks_or_cards.each do |card|
      if card.card_id == c.card_id
        card.hand_count = 0

        if card.count + 1 > KMaxCardOccurence[@current_deck_mode]
          return
        end

        card.count += 1
        found      = true
      end
    end

    unless found
      @decks_or_cards << c
      @decks_or_cards = Sorter.sort_cards @decks_or_cards
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

  # tab delegate
  def tabView(tabView, didSelectTabViewItem: tabViewItem)
    @current_class   = tabViewItem.identifier
    tabViewItem.view = @cards_view
    @cards           = nil

    @cards_view.reloadData
  end

  # tables stuff
  def numberOfRowsInTableView(tableView)
    @decks_or_cards.count
  end

  ## table delegate
  def tableView(tableView, viewForTableColumn: tableColumn, row: row)
    deck_or_card = @decks_or_cards[row]

    if deck_or_card.is_a? Card
      cell      = CardCellView.new
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

      @saved = false
      @table_view.reloadData
    end
  end

  # toolbar stuff

  # disable tabs in edition except for the current deck class and neutral cards
  def tabView(tabView, shouldSelectTabViewItem: tabViewItem)
    return true unless @in_edition
    tabViewItem.identifier =~ /#{@deck_class}|Neutral/i
  end

  # enable / disable items
  def validateToolbarItem(item)
    case item.itemIdentifier
      when 'save', 'delete', 'close', 'play', 'export'
        @in_edition
      when 'new', 'import'
        !@in_edition
      else
        true
    end
  end

  def toolbarAllowedItemIdentifiers(toolbar)
    ['new', 'import', 'save', 'search', 'close', 'delete', 'play', 'export',
     NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier]
  end

  def toolbarDefaultItemIdentifiers(toolbar)
    ['new', 'import', NSToolbarSeparatorItemIdentifier,
     'save', 'delete', 'close', 'play', 'export',
     NSToolbarFlexibleSpaceItemIdentifier, 'search']
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

      when 'new'
        item.label = 'New'._

        menu      = NSMenu.alloc.initWithTitle 'new'
        menu_item = NSMenuItem.alloc.initWithTitle('New'._, action: nil, keyEquivalent: '')
        menu.addItem menu_item

        classes = %w(Shaman Hunter Warlock Druid Warrior Mage Paladin Priest Rogue)
        classes.each do |clazz|
          menu_item            = NSMenuItem.alloc.initWithTitle(clazz._, action: 'add_deck:', keyEquivalent: '')
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
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.setMessageText('Error'._)
      alert.setInformativeText('You are currently in a deck edition and you changes have not been saved.'._)
      alert.setAlertStyle(NSCriticalAlertStyle)
      alert.beginSheetModalForWindow(self.window,
                                     modalDelegate:  self,
                                     didEndSelector: nil,
                                     contextInfo:    nil)
      return
    end

    @import = DeckImport.alloc.init
    @import.on_deck_loaded do |cards, clazz, name|
      Log.debug "#{clazz} / #{name}"

      if cards
        @saved = false
        show_deck(cards, clazz, name)
      end
    end
    self.window.beginSheet(@import.window, completionHandler: nil)
  end

  def play_deck(_)
    unless @saved
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.addButtonWithTitle('Cancel'._)
      alert.setMessageText('Save'._)
      alert.setInformativeText('You are currently in a deck edition and you changes have not been saved.'._)
      alert.setAlertStyle(NSInformationalAlertStyle)
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.addButtonWithTitle('Cancel'._)
      alert.setMessageText('Delete'._)
      alert.setInformativeText('Your deck is not saved, are you sure you want to continue, you will lose all changes.'._)
      alert.setAlertStyle(NSInformationalAlertStyle)
      response = alert.runModal

      if response == NSAlertSecondButtonReturn
        return
      end
    end

    player_view.cards = @decks_or_cards if player_view
  end

  def show_deck(deck, clazz=nil, name=nil)
    @in_edition = true

    if deck.is_a? Deck
      @current_deck   = deck
      @decks_or_cards = []
      deck.cards.each do |deck_card|
        card = Card.by_id deck_card.card_id
        if card
          card.count = deck_card.count
          @decks_or_cards << card
        end
        @decks_or_cards = Sorter.sort_cards(@decks_or_cards)
      end
      @deck_name  = deck.name
      @deck_class = deck.player_class
    else
      @current_deck   = nil
      @decks_or_cards = deck
      @deck_name      = name
      @deck_class     = clazz.sub(/^(\w)/) { |s| s.capitalize }
    end
    @current_class = @deck_class

    tab_view_item = @tab_view.tabViewItems[@tab_view.indexOfTabViewItemWithIdentifier(@current_class)]
    @tab_view.selectTabViewItem(tab_view_item)
    tab_view_item.view = @cards_view
    @cards             = nil

    #table_scroll_view = @layout.get(:table_scroll_view)
    #height = @decks_or_cards.count * 37
    #@table_view.frame = [[0, 0], [table_scroll_view.contentSize.width, height]]

    @cards_view.reloadData
    @table_view.reloadData
  end

  def add_deck(sender)
    clazz = sender.identifier

    @in_edition     = true
    @saved          = false
    @deck_class     = clazz.sub(/^(\w)/) { |s| s.capitalize }
    @current_class  = @deck_class
    @decks_or_cards = []

    tab_view_item = @tab_view.tabViewItems[@tab_view.indexOfTabViewItemWithIdentifier(@current_class)]
    @tab_view.selectTabViewItem(tab_view_item)
    tab_view_item.view = @cards_view
    @cards             = nil

    @cards_view.reloadData
    @table_view.reloadData
  end

  def delete_deck(_)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle('OK'._)
    alert.addButtonWithTitle('Cancel'._)
    alert.setMessageText('Delete'._)
    alert.setInformativeText('Are you sure you want to delete this deck ?'._)
    alert.setAlertStyle(NSInformationalAlertStyle)
    response = alert.runModal

    if response == NSAlertFirstButtonReturn
      @current_deck.destroy

      cdq.save

      @in_edition = false
      @saved      = true
      show_decks
      @table_view.reloadData
    end
  end

  def save_deck(_)
    card_count = @decks_or_cards.map(&:count).inject(0, :+)

    if card_count < @max_cards_in_deck
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.addButtonWithTitle('Cancel'._)
      alert.setMessageText('Save'._)
      alert.setInformativeText("Your deck don't have 30 cards, are you sure you want to continue ?"._)
      alert.setAlertStyle(NSInformationalAlertStyle)
      response = alert.runModal

      if response == NSAlertFirstButtonReturn
        return
      end
    end

    alert = NSAlert.alloc.init
    alert.addButtonWithTitle('OK'._)
    alert.addButtonWithTitle('Cancel'._)
    alert.setMessageText('Deck name'._)

    deck_name_input = NSTextField.alloc.initWithFrame [[0, 0], [220, 24]]
    if @deck_name
      deck_name_input.stringValue = @deck_name
    end
    alert.accessoryView = deck_name_input

    button = alert.runModal
    if button == NSAlertSecondButtonReturn
      return
    end

    deck_name_input.validateEditing
    deck_name = deck_name_input.stringValue

    if @current_deck.nil?
      @current_deck = Deck.create(:player_class => @deck_class)
    end

    @current_deck.name = deck_name

    @current_deck.cards.each do |c|
      c.destroy
    end

    @decks_or_cards.each do |card|
      @current_deck.cards.create(:card_id => card.card_id, :count => card.count)
    end

    cdq.save

    @saved = true
    alert  = NSAlert.alloc.init
    alert.addButtonWithTitle('OK'._)
    alert.setMessageText('Save'._)
    alert.setInformativeText("Deck saved"._)
    alert.setAlertStyle(NSInformationalAlertStyle)
    alert.runModal
  end

  def close_deck(_)
    close = @saved

    unless @saved
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.addButtonWithTitle('Cancel'._)
      alert.setMessageText('Delete'._)
      alert.setInformativeText('Are you sure you want to close this deck ? Your changes will not be saved.'._)
      alert.setAlertStyle(NSInformationalAlertStyle)
      response = alert.runModal

      if response == NSAlertFirstButtonReturn
        close = true
      end
    end

    if close
      @in_edition = false
      @saved      = true
      show_decks
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
    panel = NSSavePanel.savePanel
    panel.allowedFileTypes = %w(txt)
    panel.canCreateDirectories = true
    panel.nameFieldStringValue = "#{@deck_name}.txt"
    panel.title = 'Export Deck'._

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
    Importer.netdeck do |deck, clazz, name|
      unless @in_edition
        @saved = false
        show_deck(deck, clazz, name)
      end
    end
  end

end