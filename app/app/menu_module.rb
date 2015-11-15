module Menu

  def openPreferences(_)
    Configuration.use_hearthstats = !Configuration.hearthstats_token.nil?
    preferences.showWindow(nil)
  end

  # open a deck
  def open_deck(menu_item)
    deck = Deck.by_name(menu_item.title)
    if @player
      @player.show_deck(deck.playable_cards, deck.name)
    end
    Game.instance.with_deck(deck)
    if Configuration.remember_last_deck
      Configuration.last_deck_played = "#{deck.name}##{deck.version}"
    end
  end

  # reset the trackers
  def reset(_)
    @player.game_start
    @opponent.game_start
    Hearthstone.instance.reset
  end

  def clear(_)
    @player.clear
  end

  def reload_deck_menu
    deck_menu = NSApp.mainMenu.itemWithTitle :decks._
    deck_menu.submenu.removeAllItems

    deck_menu.submenu.addItemWithTitle(:deck_manager._, action: 'open_deck_manager:', keyEquivalent: 'm')
    deck_menu.submenu.addItemWithTitle(:reset._, action: 'reset:', keyEquivalent: 'r')
    deck_menu.submenu.addItemWithTitle(:clear._, action: 'clear:', keyEquivalent: '')
    deck_menu.submenu.addItemWithTitle(:save_all._, action: 'save_decks:', keyEquivalent: '')
    deck_menu.submenu.addItem NSMenuItem.separatorItem

    decks = {}
    Deck.where(is_active: true)
      .sort_by(:player_class)
      .sort_by(:name, case_insensitive: true)
      .each do |deck|
      unless decks.has_key?(deck.player_class.downcase._)
        decks[deck.player_class.downcase._] = []
      end
      decks[deck.player_class.downcase._] << deck
    end

    Hash[decks.sort_by {|k, _| k}].each do |clazz, _decks|
      item = NSMenuItem.alloc.initWithTitle(clazz, action: nil, keyEquivalent: '')
      deck_menu.submenu.addItem item

      menu = NSMenu.alloc.init

      _decks.each do |deck|
        menu.addItemWithTitle(deck.name, action: 'open_deck:', keyEquivalent: '')
      end
      item.setSubmenu(menu)
    end

  end

  def close_window_menu(enabled)
    window_menu = NSApp.mainMenu.itemWithTitle :window._
    close_window = window_menu.submenu.itemWithTitle :close._
    close_window.enabled = enabled
  end


  def open_deck_manager(data)
    # change windows level
    if @player
      @player.set_level NSNormalWindowLevel
    end
    if @opponent
      @opponent.set_level NSNormalWindowLevel
    end

    deck_manager.showWindow(nil)
    deck_manager.player_view = @player

    if data.is_a? Hash
      deck_manager.import(data)
    end

    close_window_menu true
  end


  # lock / unlock windows
  def lock_windows(menu_item)
    Configuration.windows_locked ? menu_item.title = :lock_windows._ : menu_item.title = :unlock_windows._

    Configuration.windows_locked = !Configuration.windows_locked
  end


  def ask_download_images(_)
    current_locale = Configuration.hearthstone_locale

    popup = NSPopUpButton.new
    popup.frame = [[0, 0], [299, 24]]

    GeneralPreferencesLayout::KHearthstoneLocales.each do |hs_locale, osx_locale|
      locale = NSLocale.alloc.initWithLocaleIdentifier osx_locale
      display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

      item = NSMenuItem.alloc.initWithTitle(display, action: nil, keyEquivalent: '')
      popup.menu.addItem item

      if current_locale == hs_locale
        popup.selectItem item
      end
    end

    if current_locale.nil?
      popup.selectItemAtIndex -1
    end

    rep = NSAlert.alert(:images._,
                        buttons: [:ok._],
                        informative: :cards_not_found._,
                        view: popup)
    if rep
      choosen = popup.selectedItem.title

      GeneralPreferencesLayout::KHearthstoneLocales.each do |hs_locale, osx_locale|
        locale = NSLocale.alloc.initWithLocaleIdentifier osx_locale
        display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

        if choosen == display
          Configuration.hearthstone_locale = hs_locale
        end
      end

      download_images
    end
  end

  def download_images
    @downloader = Downloader.new
    @downloader.showWindow(nil)
    @downloader.download do
      NSUserDefaults.standardUserDefaults.setObject(ImageCache::IMAGES_VERSION, forKey: 'image_version')

      @downloader.close if @downloader
      @downloader = nil
    end
  end

  def save_decks(_)
    panel = NSOpenPanel.savePanel
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.prompt = :save._

    if panel.runModal == NSFileHandlingPanelOKButton
      Exporter.export_to_files(panel.directoryURL.path)
    end
  end

  def reset_all_data(_)
    response = NSAlert.alert(:reset_all._,
                             buttons: [:ok._, :cancel._],
                             informative: :reset_all_confirm._
    )

    if response == NSAlertFirstButtonReturn
      # since 0.11, cascade is set on deletion rule
      # but before that version, when you deleted a deck, all cards
      # where kept, this is why we force the deletion here
      Deck.destroy_all!
      DeckCard.destroy_all!
      Statistic.destroy_all!

      reload_deck_menu
      NSAlert.alert(:reset_all._,
                    buttons: [:ok._],
                    informative: :all_data_deleted._
      )
    end
  end

  def rebuild_cards(_)
    Card.destroy_all
    Mechanic.destroy_all
    cdq.save

    response = NSAlert.alert(:rebuild_card_database._,
                             buttons: [:ok._],
                             informative: :rebuild_card_database_info._)
    if response == NSAlertFirstButtonReturn
      @app_will_restart = true

      NSApplication.sharedApplication.terminate(nil)
      exit(0)
    end
  end

  def open_debug(_)
    NSWorkspace.sharedWorkspace.activateFileViewerSelectingURLs ['/Library/Logs/HSTracker'.home_path.fileurl]
  end
end
