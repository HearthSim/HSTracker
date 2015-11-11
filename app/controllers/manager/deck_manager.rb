class DeckManager < NSWindowController
  include CDQ

  KMaxCardOccurence = {
    arena: 30,
    constructed: 2
  }

  attr_accessor :player_view

  def init
    super.tap do
      @layout = DeckManagerLayout.new
      self.window = @layout.window
      self.window.delegate = self

      @saved = true
      @in_edition = false

      # init tabs
      @tabs = @layout.get(:tabs)
      @tabs.setAction 'tab_changed:'
      @tabs.setTarget self
      @tabs.setSegmentCount ClassesData::KClasses.size

      ClassesData::KClasses.each_with_index do |clazz, idx|
        if Configuration.skin == :default || clazz == 'Neutral'
          @tabs.setLabel(clazz.downcase._, forSegment: idx)
        else
          @tabs.setImage(ImageCache.hero(clazz, size: [20, 20]), forSegment: idx)
        end
      end

      @tabs.setSelected(true, forSegment: 0)
      @current_class = ClassesData::KClasses[0]

      # init table
      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      @table_view.doubleAction = 'double_click:'
      @table_view.action = 'click:'
      @table_view.delegate = self
      @table_view.dataSource = self

      @table_menu = NSMenu.alloc.initWithTitle 'table_identifier'
      menu_item = NSMenuItem.alloc.initWithTitle(:play._, action: 'play_deck:', keyEquivalent: '')
      menu_item.identifier = 'table_identifier'
      @table_menu.addItem menu_item
      @table_menu.addItem NSMenuItem.separatorItem
      menu_item = NSMenuItem.alloc.initWithTitle(:export._, action: 'export_deck:', keyEquivalent: '')
      menu_item.identifier = 'table_identifier'
      @table_menu.addItem menu_item
      menu_item = NSMenuItem.alloc.initWithTitle(:delete._, action: 'delete_deck:', keyEquivalent: '')
      @table_menu.addItem menu_item
      menu_item.identifier = 'table_identifier'
      @table_view.menu = @table_menu

      # init card view
      @cards_view = @layout.get(:cards_view)
      @cards_view.dataSource = self
      @cards_view.delegate = self

      grid_layout = JNWCollectionViewGridLayout.alloc.initWithCollectionView(@cards_view)
      grid_layout.delegate = self
      grid_layout.itemSize = [191, 260]
      @cards_view.collectionViewLayout = grid_layout
      @cards_view.registerClass(CardItemView, forCellWithReuseIdentifier: 'card_item')

      @left = @layout.get(:left)

      @toolbar = NSToolbar.alloc.initWithIdentifier 'toolbar'
      @toolbar.displayMode = NSToolbarDisplayModeIconOnly
      @toolbar.delegate = self
      self.window.toolbar = @toolbar

      @card_count = @layout.get(:card_count)
      @curve_view = @layout.get(:curve_view)

      @show_stats = @layout.get(:show_stats)
      @show_stats.setTarget self
      @show_stats.setAction 'show_stats:'
    end
  end

  def showWindow(_)
    super.tap do
      @max_cards_in_deck = 30

      # preparation for arena
      @current_deck_mode = :constructed

      # load decks
      show_decks
      @table_view.reloadData

      @cards = nil
      @cards_view.reloadData

      check_clipboad_net_deck

      NSNotificationCenter.defaultCenter.observe('skin') do |_|
        unless @in_edition
          @table_view.reloadData
        end
        ClassesData::KClasses.each_with_index do |clazz, idx|
          if Configuration.skin == :default || clazz == 'Neutral'
            @tabs.setLabel(clazz._, forSegment: idx)
            @tabs.setImage(nil, forSegment: idx)
          else
            @tabs.setLabel(nil, forSegment: idx)
            @tabs.setImage(ImageCache.hero(clazz, :size => [20, 20]), forSegment: idx)
          end
        end
      end

      NSEvent.addLocalMonitorForEventsMatchingMask(NSKeyDownMask,
                                                   handler: -> (event) {
                                                     is_cmd = (event.modifierFlags & NSCommandKeyMask == NSCommandKeyMask)
                                                     is_shift = (event.modifierFlags & NSShiftKeyMask == NSShiftKeyMask)
                                                     unless is_cmd
                                                       return event
                                                     end

                                                     case event.keyCode
                                                     when 35
                                                       if @in_edition
                                                         play_deck(nil)
                                                         event = nil
                                                       end

                                                       # close window
                                                     when 6
                                                       if is_shift
                                                         self.window.performClose(nil)
                                                       elsif @in_edition
                                                         close_deck(nil)
                                                       end
                                                       event = nil

                                                       # cmd-f
                                                     when 3
                                                       @search_field.becomeFirstResponder
                                                       event = nil

                                                       # cmd-s
                                                     when 1
                                                       if @in_edition && !@saved
                                                         save_deck(nil)
                                                         event = nil
                                                       end
                                                     end
                                                     return event
      })
    end
  end

  def import(data)
    return if data.nil?

    ignore_cards = [
      'GAME_005'
    ]

    @saved = false
    cards = []
    data[:cards].each do |card|
      next if ignore_cards.include? card.card_id

      r_card = Card.by_id card.card_id
      next unless r_card.collectible
      r_card.count = card.count
      cards << r_card
    end

    show_deck(cards, data[:class])
  end

  def check_is_saved_on_close
    close = @saved

    unless @saved
      response = NSAlert.alert(:delete._,
                               buttons: [:ok._, :cancel._],
                               informative: :sure_close_deck._
                               )

      if response == NSAlertFirstButtonReturn
        close = true
      end
    end
    close
  end

  def show_decks
    @decks_or_cards = []
    Deck.active.all.sort_by(:name, case_insensitive: true).each do |deck|
      @decks_or_cards << deck
    end

    ClassesData::KClasses.each_with_index do |_, index|
      @tabs.setEnabled(true, forSegment: index)
    end if @tabs

    @table_view.menu = @table_menu if @table_view
  end

  def cards
    @cards ||= begin
      clazz = @current_class
      if @current_class == 'Neutral'
        clazz = nil
      end
      Card.per_lang.playable
      .where(player_class: clazz)
      .sort_by(:cost)
      .sort_by(:card_type, order: :desc)
      .sort_by(:name, case_insensitive: true)
    end
  end

  # JNWCollection stuff
  def collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    cell = @cards_view.dequeueReusableCellWithIdentifier('card_item')
    card = cards[indexPath.jnw_item]
    cell.delegate = self
    cell.card = card
    cell.mode = @current_deck_mode

    count = 0
    if @in_edition
      @decks_or_cards.each do |c|
        next if card.nil? || c.nil?
        next if !card.respond_to?(:card_id) || !c.respond_to?(:card_id)
        next if !c.respond_to?(:count)

        if card.card_id == c.card_id
          count = c.count
        end
      end
    end
    cell.count = count

    cell
  end

  # todo make something with this ?
  def missing_image(card)
    error(:cards, "image for #{card.card_id} is missing")
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

    cell = collectionView.cellForItemAtIndexPath(indexPath)
    c = cell.card

    found = false
    @decks_or_cards.each do |card|
      if card.card_id == c.card_id
        card.hand_count = 0

        if card.count + 1 > KMaxCardOccurence[@current_deck_mode] || (@current_deck_mode == :constructed && card.rarity == :legendary._)
          return
        end

        card.count += 1
        found = true
      end
    end

    unless found
      @decks_or_cards << c
      @decks_or_cards.sort_cards!
    end

    @card_count.stringValue = "#{card_count + 1} / #{@max_cards_in_deck}"

    @curves.cards = @decks_or_cards if @curves
    @table_view.reloadData
    @cards_view.reloadData
    @saved = false
  end

  # CardItemView delegate
  def hover(cell)
    rect = self.window.contentView.convertRect(cell.bounds, fromView: cell)
    card = cell.card

    return if card.nil? || card.name.nil?

    @popover.close if @popover && @popover.isShown

    @popover ||= begin
      popover = NSPopover.new
      popover.animates = false
      @tooltip ||= Tooltip.new
      popover.contentViewController = @tooltip
      popover
    end

    @tooltip.card = cell.card
    @popover.showRelativeToRect(rect, ofView: self.window.contentView, preferredEdge: NSMinXEdge)
  end

  def out(_)
    @popover.close if @popover && @popover.isShown
  end

  # nssegmentedcontrol
  def tab_changed(_)
    @current_class = ClassesData::KClasses[@tabs.selectedSegment]
    @cards = nil

    str = @search_field.stringValue
    if str && !str.empty?
      search_card(str)
    else
      @cards_view.reloadData
    end
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
      cell = CardCellView.new
      cell.card_size = :big
      cell.side = :opponent
      cell.card = deck_or_card
    else
      cell = DeckCellView.new
      cell.deck = deck_or_card
    end

    cell
  end

  # disable selection
  def selectionShouldChangeInTableView(tableView)
    false
  end

  def click(_)
    deck_or_card = @decks_or_cards[@table_view.clickedRow]

    if deck_or_card.is_a? Deck
      show_curve(deck_or_card)
    end
  end

  def double_click(_)
    deck_or_card = @decks_or_cards[@table_view.clickedRow]

    if deck_or_card.is_a? Deck
      show_deck(deck_or_card)
    else
      if deck_or_card.count == 1
        @decks_or_cards.delete(deck_or_card)
      else
        deck_or_card.count -= 1
      end

      card_count = @decks_or_cards.count_cards
      @card_count.stringValue = "#{card_count} / #{@max_cards_in_deck}"
      @curves.cards = @decks_or_cards if @curves
      @saved = false
      @table_view.reloadData
      @cards_view.reloadData
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

  def toolbarAllowedItemIdentifiers(_)
    ['new', 'arena', 'import', 'save',
     'search', 'close', 'delete', 'play', 'export',
     'donate', 'twitter', 'hearthstats',
     NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier]
  end

  def toolbarDefaultItemIdentifiers(_)
    ['new', 'arena', 'import', NSToolbarSeparatorItemIdentifier,
     'save', 'delete', 'close', 'play', 'export',
     NSToolbarFlexibleSpaceItemIdentifier, 'search', 'hearthstats', 'donate', 'twitter']
  end

  def toolbar(toolbar, itemForItemIdentifier: identifier, willBeInsertedIntoToolbar: flag)
    item = NSToolbarItem.alloc.initWithItemIdentifier(identifier)
    case identifier
    when 'import'
      item.label = :import._
      item.toolTip = :import._
      image = 'import'.nsimage
      image.setTemplate true

      menu = NSMenu.alloc.initWithTitle identifier
      menu_item = NSMenuItem.alloc.initWithTitle('', action: nil, keyEquivalent: '')
      menu_item.image = image
      menu.addItem menu_item

      menu_item = NSMenuItem.alloc.initWithTitle(:from_web._, action: 'import_deck:', keyEquivalent: '')
      menu_item.identifier = 'web'
      menu.addItem menu_item

      menu_item = NSMenuItem.alloc.initWithTitle(:from_file._, action: 'import_deck:', keyEquivalent: '')
      menu_item.identifier = 'file'
      menu.addItem menu_item

      menu_item = NSMenuItem.alloc.initWithTitle(:from_hearthstats._, action: 'import_deck:', keyEquivalent: '')
      menu_item.identifier = 'hearthstats'
      menu.addItem menu_item

      menu_item = NSMenuItem.alloc.initWithTitle(:from_hearthstats_force._, action: 'import_deck:', keyEquivalent: '')
      menu_item.identifier = 'hearthstats_force'
      menu.addItem menu_item

      popup = NSPopUpButton.alloc.initWithFrame [[0, 0], [50, 32]]
      popup.cell.arrowPosition = NSPopUpNoArrow
      popup.bordered = false
      popup.pullsDown = true
      popup.menu = menu
      item.view = popup

    when 'new', 'arena'
      label = (identifier == 'new') ? :new._ : :arena_deck._
      action = (identifier == 'new') ? 'add_deck:' : 'add_area_deck:'

      item.label = label

      menu = NSMenu.alloc.initWithTitle identifier
      menu_item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
      menu.addItem menu_item

      classes = ClassesData::KClasses[0...-1]
      classes.each do |clazz|
        menu_item = NSMenuItem.alloc.initWithTitle(clazz._, action: action, keyEquivalent: '')
        menu_item.image = ImageCache.hero(clazz)
        menu_item.identifier = clazz
        menu.addItem menu_item
      end
      popup = NSPopUpButton.alloc.initWithFrame [[0, 0], [100, 22]]
      popup.bordered = false
      popup.pullsDown = true
      popup.menu = menu
      item.view = popup

    when 'close'
      item.label = :close._
      item.toolTip = :close._
      image = 'close'.nsimage
      image.setTemplate true
      item.image = image
      item.target = self
      item.action = 'close_deck:'

    when 'save'
      item.label = :save._
      item.toolTip = :save._
      image = 'save'.nsimage
      image.setTemplate true
      item.image = image
      item.target = self
      item.action = 'save_deck:'

    when 'export'
      item.label = :export._
      item.toolTip = :export._
      image = 'export'.nsimage
      image.setTemplate true
      item.image = image
      item.target = self
      item.action = 'export_deck:'

    when 'play'
      item.label = :play._
      item.toolTip = :play._
      image = 'play'.nsimage
      image.setTemplate true
      item.image = image
      item.target = self
      item.action = 'play_deck:'

    when 'delete'
      item.label = :delete._
      item.toolTip = :delete._
      image = 'delete'.nsimage
      image.setTemplate true
      item.image = image
      item.target = self
      item.action = 'delete_deck:'

    when 'donate'
      item.label = :donate._
      item.toolTip = :donate._
      image = 'donate'.nsimage
      item.image = image
      item.target = self
      item.action = 'donate:'

    when 'twitter'
      item.label = 'Twitter'
      item.toolTip = 'Twitter'
      image = 'twitter'.nsimage
      item.image = image
      item.target = self
      item.action = 'twitter:'

    when 'hearthstats'
      item.label = 'HearthStats'
      item.toolTip = 'HearthStats'
      image = 'hearthstats_icon'.nsimage
      item.image = image
      item.target = self
      item.action = 'hearthstats:'

    when 'search'
      item.label = :search._

      @search_field = NSSearchField.alloc.initWithFrame(NSZeroRect)
      @search_field.target = self
      @search_field.action = 'search:'
      @search_field.cell.cancelButtonCell.target = self
      @search_field.cell.cancelButtonCell.action = 'cancel_search:'
      @search_field.frame = [[0, 0], [200, 0]]
      item.view = @search_field
    end
    item
  end

  # actions
  def import_deck(sender)
    if @in_edition && !@saved
      NSAlert.alert(:error._,
                    buttons: [:ok._],
                    informative: :deck_edition_not_saved._,
                    style: NSCriticalAlertStyle,
                    window: self.window
                    )
      return
    end

    if sender.identifier == 'web'
      @import = DeckImport.alloc.init

      @import.on_deck_loaded do |cards, clazz, name, arena|
        if cards
          log(:import, class: clazz, name: name, is_arena: arena)
          @saved = false
          show_deck(cards, clazz, name, arena)
        end
      end
      self.window.show_sheet(@import.window)
    elsif sender.identifier == 'hearthstats' || sender.identifier == 'hearthstats_force'

      if sender.identifier == 'hearthstats_force'
        key = 'hearthstats_last_get_decks'
        NSUserDefaults.standardUserDefaults.setObject(0, forKey: key)
      end

      classes = {
        1 => 'Druid',
        2 => 'Hunter',
        3 => 'Mage',
        4 => 'Paladin',
        5 => 'Priest',
        6 => 'Rogue',
        7 => 'Shaman',
        8 => 'Warlock',
        9 => 'Warrior'
      }

      HearthStatsAPI.get_decks do |data|
        break if data.nil?

        data.each do |json_deck|
          deck_id = json_deck['deck']['id']
          deck_name = json_deck['deck']['name']
          deck_class = classes[json_deck['deck']['klass_id']]

          next if deck_class.nil?

          # search for a deck with the same id
          deck = Deck.where(hearthstats_id: deck_id).first

          if deck.nil?

            hearthstats_version_id = nil
            current_version = json_deck['current_version']
            if current_version && json_deck.has_key?('versions')
              hearthstats_version_id = json_deck['versions'].select { |d| d['version'] == json_deck['current_version'] }
              .first['deck_version_id']
            end

            deck = Deck.create name: deck_name,
              player_class: deck_class,
              arena: false,
              version: json_deck['current_version'].to_i,
              is_active: true,
              hearthstats_id: deck_id,
              hearthstats_version_id: hearthstats_version_id
          end

          if deck.cards && !deck.cards.length.zero?
            deck.cards.each do |c|
              c.destroy
            end
          end
          if json_deck['cards'].nil?
            NSAlert.alert('The import of this deck can not be completed. Please create an issue on Github and paste the content of your last log file.',
                          buttons: [:ok._],
                          window: self.window)
            deck.destroy
            error(:import, json_deck)
            next
          else
            json_deck['cards'].each do |json_card|
              deck.cards.create(card_id: json_card['id'], count: json_card['count'].to_i)
            end
          end
        end

        if data.count.zero?
          message = :no_deck_to_import._
        else
          message = :decks_imported._(number: data.count)
        end
        NSAlert.alert(message,
                      buttons: [:ok._],
        window: self.window) do |_|
          cdq.save

          # reload decks
          show_decks
          @table_view.reloadData
        end
      end
    else
      panel = NSOpenPanel.openPanel
      panel.canChooseFiles = true
      panel.canChooseDirectories = false
      panel.allowsMultipleSelection = true
      panel.allowedFileTypes = ['txt']

      if panel.runModal == NSFileHandlingPanelOKButton
        panel.filenames.each do |filename|
          Importer.import_from_file(filename) do |cards, clazz, name, arena|
            log(:import, class: clazz, name: name, is_arena: arena)

            if cards
              show_deck(cards, clazz, name, arena)
              save_deck(nil)
            end
          end
        end
      end
    end
  end

  def play_deck(sender)
    if sender && sender.respond_to?('identifier') && sender.identifier == 'table_identifier'
      row = @table_view.clickedRow
      deck = @decks_or_cards[row]
      if deck.is_a?(Deck)
        name = deck.name
        cards = deck.playable_cards
      end
    else
      name = @deck_name
      cards = @decks_or_cards
      deck = @current_deck
    end

    return unless cards

    if @saved
      _play_deck(deck, cards, name)
    else
      NSAlert.alert(:play._,
                    buttons: [:ok._, :cancel._],
                    informative: :deck_not_saved._,
                    style: NSInformationalAlertStyle,
                    window: self.window
      ) do |response|
        if response == NSAlertSecondButtonReturn
          break
        end

        _play_deck(deck, cards, name)
      end
    end
  end

  def _play_deck(deck, cards, name)
    player_view.show_deck(cards, name) if player_view
    Game.instance.with_deck(deck)
    if Configuration.remember_last_deck
      Configuration.last_deck_played = "#{deck.name}##{deck.version}"
    end
  end

  def show_deck(deck, clazz=nil, name=nil, arena=false)
    @table_view.menu = nil

    @in_edition = true
    @show_stats.enabled = true

    if deck.is_a? Deck
      @current_deck = deck

      @current_deck.arena.to_bool ? @current_deck_mode = :arena : @current_deck_mode = :constructed
      @decks_or_cards = @current_deck.playable_cards
      @deck_name = deck.name
      @deck_class = deck.player_class
    else
      arena ? @current_deck_mode = :arena : @current_deck_mode = :constructed
      @current_deck = nil
      @decks_or_cards = deck
      @deck_name = name
      @deck_class = clazz
    end
    @current_class = @deck_class

    selected_class = ClassesData::KClasses.index(@current_class)
    ClassesData::KClasses.each_with_index do |claz, index|
      enabled = selected_class == index || claz == 'Neutral'
      @tabs.setEnabled(enabled, forSegment: index)
      @tabs.setSelected(selected_class == index, forSegment: index)
    end
    @cards = nil

    card_count = @decks_or_cards.count_cards
    @card_count.stringValue = "#{card_count} / #{@max_cards_in_deck}"

    @cards_view.reloadData
    @table_view.reloadData

    show_curve
  end

  def show_deck_stats(deck)
    @curve_view.subviews = []

    unless @deck_stats
      @deck_stats = DeckStatsView.new
    end
    @deck_stats.frame = @curve_view.bounds
    @curve_view << @deck_stats
    @deck_stats.deck = deck
  end

  def show_curve(deck=nil)
    @curve_view.subviews = []
    unless @curves
      @curves = CurveView.new
    end
    @curves.frame = @curve_view.bounds
    @curve_view << @curves
    @curves.cards = deck.nil? ? @decks_or_cards : deck.playable_cards
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

    @in_edition = true
    @saved = false
    @deck_class = clazz.sub(/^(\w)/) { |s| s.capitalize }
    @current_class = @deck_class
    @decks_or_cards = []
    @current_deck = nil

    @card_count.stringValue = "0 / #{@max_cards_in_deck}"

    selected_class = ClassesData::KClasses.index(@current_class)
    ClassesData::KClasses.each_with_index do |claz, index|
      enabled = selected_class == index || claz == 'Neutral'
      @tabs.setEnabled(enabled, forSegment: index)
      @tabs.setSelected(selected_class == index, forSegment: index)
    end
    @cards = nil

    @cards_view.reloadData
    @table_view.reloadData

    show_curve
  end

  def delete_deck(sender)
    row = @table_view.clickedRow

    NSAlert.alert(:delete._,
                  buttons: [:ok._, :cancel._],
                  informative: :sure_delete_deck._,
                  window: self.window
    ) do |response|

      if response == NSAlertFirstButtonReturn

        if sender && sender.respond_to?('identifier') && sender.identifier == 'table_identifier'
          deck = @decks_or_cards[row]
        else
          deck = @current_deck
        end

        break if deck.is_a?(Card) || deck.is_a?(PlayCard)

        if Configuration.use_hearthstats && !deck.hearthstats_id.nil? && !deck.hearthstats_id.zero?
          NSAlert.alert(:delete._,
                        buttons: [:ok._, :cancel._],
                        informative: :delete_deck_hearthstats._,
          window: self.window) do |res|
            if res == NSAlertFirstButtonReturn
              HearthStatsAPI.delete_deck(deck)
            end
          end
        end

        deck.destroy

        cdq.save

        @current_deck = nil
        @deck_name = nil
        @deck_class = nil
        @in_edition = false
        @saved = true
        show_decks

        NSNotificationCenter.defaultCenter.post('deck_change')
        @card_count.stringValue = ''
        @table_view.reloadData
        @cards_view.reloadData
        @curve_view.subviews = []

        Notification.post(:delete_deck._, :deck_deleted._)
      end
    end
  end

  def save_deck(_)
    card_count = @decks_or_cards.count_cards

    if card_count < @max_cards_in_deck
      NSAlert.alert(:save._,
                    buttons: [:ok._, :cancel._],
                    informative: :deck_incomplete._,
                    window: self.window
      ) do |response|

        if response == NSAlertSecondButtonReturn
          break
        end
        _save_deck
      end
    else
      _save_deck
    end
  end

  def _save_deck
    deck_name_input = NSTextField.alloc.initWithFrame [[0, 0], [220, 24]]
    if @deck_name
      deck_name_input.stringValue = @deck_name
    end

    buttons = [:save._, :cancel._]
    current_version = 1.0.round(1)
    next_minor = (current_version + 0.1).round(1)
    next_major = (current_version.to_i + 1.0).round(1)
    is_new_deck = true

    unless @current_deck.nil?
      is_new_deck = false
      current_version = @current_deck.version.round(1)
      next_minor = (current_version + 0.1).round(1)
      next_major = (current_version.to_i + 1.0).round(1)

      save_as = :save_version._(version: current_version)
      save_minor = :save_version._(version: next_minor)
      save_major = :save_version._(version: next_major)

      buttons = [save_as, save_minor, save_major, :cancel._]
    end

    NSAlert.alert(:deck_name._,
                  :buttons => buttons,
                  :view => deck_name_input,
                  :window => self.window
    ) do |response|

      if (buttons.length == 2 && response == NSAlertSecondButtonReturn) || (buttons.length == 4 && response == NSAlertThirdButtonReturn + 1)
        break
      end

      deck_name_input.validateEditing
      deck_name = deck_name_input.stringValue

      if is_new_deck
        # new deck
        @current_deck = Deck.create(player_class: @deck_class,
                                    version: current_version,
                                    is_active: true)
      elsif response == NSAlertFirstButtonReturn
        # should I change something in the deck here ?
        # we still have the same version...
      else
        # new version of the deck
        new_version = case response
        when NSAlertSecondButtonReturn
          next_minor
        when NSAlertThirdButtonReturn
          next_major
        end

        @current_deck.is_active = false
        new_deck = Deck.create(player_class: @deck_class,
                               version: new_version,
                               is_active: true,
                               arena: @current_deck.arena,
                               name: deck_name,
                               deck: @current_deck,
                               hearthstats_id: @current_deck.hearthstats_id,
                               hearthstats_version_id: nil
                               )
        @current_deck = new_deck
      end

      @current_deck.name = deck_name

      @current_deck.cards.each do |c|
        c.destroy
      end

      @decks_or_cards.each do |card|
        @current_deck.cards.create(card_id: card.card_id, count: card.count)
      end

      cdq.save

      @saved = true
      NSNotificationCenter.defaultCenter.post('deck_change')

      Notification.post(:deck_saved._, :deck_has_been_saved._)

      if Configuration.use_hearthstats
        NSAlert.alert(:deck_save._,
                      buttons: [:ok._, :cancel._],
                      informative: :save_deck_hearthstats._,
        window: self.window) do |res|
          break if res == NSAlertSecondButtonReturn

          if @current_deck.hearthstats_id.nil? || @current_deck.hearthstats_id.zero?
            HearthStatsAPI.post_deck(@current_deck)
          elsif !@current_deck.hearthstats_version_id.nil?
            HearthStatsAPI.update_deck(@current_deck)
          else
            HearthStatsAPI.post_deck_version(@current_deck)
          end
        end
      end
    end
  end

  def close_deck(_)
    if @saved
      _close_deck
    else
      NSAlert.alert(:close._,
                    buttons: [:ok._, :cancel._],
                    informative: :sure_close_deck._,
                    window: self.window
      ) do |response|
        if response == NSAlertFirstButtonReturn
          _close_deck
        end
      end
    end
  end

  def _close_deck
    @in_edition = false
    @saved = true
    @current_deck = nil
    @deck_name = nil
    @deck_class = nil
    show_decks
    @card_count.stringValue = ''
    @table_view.reloadData
    @cards_view.reloadData

    @curve_view.subviews = []
    @show_stats.enabled = false
  end

  def search(sender)
    str = sender.stringValue

    if str && !str.empty?
      search_card(str)
    else
      cancel_search(sender)
    end
  end

  def search_card(str)
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

  def export_deck(sender)
    name = cards = nil

    if sender && sender.respond_to?('identifier') && sender.identifier == 'table_identifier'
      row = @table_view.clickedRow
      deck = @decks_or_cards[row]

      if deck.is_a?(Deck)
        name = deck.name
        cards = deck.playable_cards
      end
    else
      name = @deck_name
      cards = @decks_or_cards
    end

    return if name.nil? || cards.nil?

    panel = NSSavePanel.savePanel
    panel.allowedFileTypes = %w(txt)
    panel.canCreateDirectories = true
    panel.nameFieldStringValue = "#{name}.txt"
    panel.title = :export_deck._

    result = panel.runModal
    if result == NSOKButton
      path = panel.URL.path

      content = cards.map do |card|
        c = Card.by_id(card.card_id)
        "#{card.count} #{c.english_name}"
      end.join("\n")

      content.nsdata.write_to(path)
      Notification.post(:export_deck._, :deck_has_been_exported._)
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

  def hearthstats(_)
    NSWorkspace.sharedWorkspace.openURL 'http://hearthstats.net'.nsurl
  end

  def twitter(_)
    NSWorkspace.sharedWorkspace.openURL 'https://twitter.com/hstracker_mac'.nsurl
  end

  def show_stats(_)
    @stats_panel ||= StatisticPanel.new
    @stats_panel.deck = @current_deck

    self.window.show_sheet(@stats_panel.window)
  end

end
