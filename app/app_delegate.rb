class AppDelegate
  include CDQ

  Log = Motion::Log

  def applicationDidFinishLaunching(notification)
    # init logs
    Log.level = :debug

    Log.addLogger DDTTYLogger.sharedInstance

    return true if RUBYMOTION_ENV == 'test'

    file_logger = DDFileLogger.new
    file_logger.rollingFrequency = 60 * 60 * 12
    file_logger.logFileManager.maximumNumberOfLogFiles = 7
    Log.addLogger file_logger

    cdq.setup

    #AFNetworkActivityLogger.sharedLogger.startLogging

    show_splash_screen

    # load cards into database if needed
    DatabaseGenerator.init_database(@splash) do

      # upgrade decks to have versions number
      Deck.upgrade_versions

      NSApp.mainMenu = MainMenu.new.menu

      @player = PlayerTracker.new
      @player.showWindow(self)
      @player.window.orderFrontRegardless

      @opponent = OpponentTracker.new
      if Configuration.show_opponent_tracker
        @opponent.showWindow(self)
        @opponent.window.orderFrontRegardless
      end

      @timer_hud = TimerHud.new
      if Configuration.show_timer
        @timer_hud.showWindow(self)
      end

      Game.instance.player_tracker = @player
      Game.instance.opponent_tracker = @opponent
      Game.instance.timer_hud = @timer_hud

      if Configuration.remember_last_deck
        last_deck_played = Configuration.last_deck_played
        unless last_deck_played.nil?
          name, version = last_deck_played.split('#')
          deck = Deck.where(:name => name).and(:version).eq(version).first
          if deck
            @player.show_deck(deck.playable_cards, deck.name)
            Game.instance.with_deck(deck)
          end
        end
      end

      Hearthstone.instance.on(:app_running) do |is_running|
        Log.info "Hearthstone is running? #{is_running}"
      end

      Hearthstone.instance.on(:app_activated) do |is_active|
        Log.info "Hearthstone is active? #{is_active}"
        if is_active
          @player.set_level NSScreenSaverWindowLevel
          @opponent.set_level NSScreenSaverWindowLevel
          @timer_hud.set_level NSScreenSaverWindowLevel
        else
          @player.set_level NSNormalWindowLevel
          @opponent.set_level NSNormalWindowLevel
          @timer_hud.set_level NSNormalWindowLevel
        end
      end

      Configuration.use_hearthstats = !Configuration.hearthstats_token.nil?

      NSNotificationCenter.defaultCenter.observe 'deck_change' do |_|
        reload_deck_menu
      end

      if Hearthstone.instance.is_hearthstone_running?
        Dispatch::Queue.main.async do
          Hearthstone.instance.start
        end
      end

      @splash.window.orderOut(self)
      @splash = nil

      VersionChecker.check

      NSNotificationCenter.defaultCenter.observe 'AppleLanguages_changed' do |_|
        response = NSAlert.alert(:language_change._,
                                 buttons: [:ok._, :cancel._],
                                 informative: :language_change_restart._)
        if response == NSAlertFirstButtonReturn
          @app_will_restart = true

          NSApplication.sharedApplication.terminate(nil)
          exit(0)
        end
      end

      NSNotificationCenter.defaultCenter.observe 'open_deck_manager' do |notif|
        open_deck_manager notif.userInfo
      end

      if ImageCache.need_download?
        ask_download_images(nil)
      end
    end
  end

  def show_splash_screen
    @splash = LoadingScreen.new
    @splash.showWindow(nil)
  end

  # preferences
  def preferences
    @preferences ||= begin
      MASPreferencesWindowController.alloc.initWithViewControllers(
        [
          GeneralPreferences.new,
          InterfacePreferences.new,
          ColorPreferences.new,
          SyncPreferences.new
        ],
        title: :preferences._)
    end
  end

  def openPreferences(_)
    Configuration.use_hearthstats = !Configuration.hearthstats_token.nil?
    preferences.showWindow(nil)
  end

  # deck manager
  def deck_manager
    @deck_manager ||= begin
      manager = DeckManager.new
      manager.window.delegate = self
      manager
    end
  end

  def open_deck_manager(data)
    # change windows level
    @player.set_level NSNormalWindowLevel
    @opponent.set_level NSNormalWindowLevel

    deck_manager.showWindow(nil)
    deck_manager.player_view = @player

    if data.is_a? Hash
      deck_manager.import(data)
    end

    close_window_menu true
  end

  # nswindowdelegate
  def windowShouldClose(_)
    deck_manager.check_is_saved_on_close
  end

  def windowWillClose(_)
    # change windows level back
    if Hearthstone.instance.is_active?
      @player.set_level NSScreenSaverWindowLevel
      @opponent.set_level NSScreenSaverWindowLevel
    end

    close_window_menu false
    @deck_manager = nil
  end

  # lock / unlock windows
  def lock_windows(menu_item)
    Configuration.windows_locked ? menu_item.title = :lock_windows._ : menu_item.title = :unlock_windows._

    Configuration.windows_locked = !Configuration.windows_locked
  end

  # open a deck
  def open_deck(menu_item)
    deck = Deck.by_name(menu_item.title)
    @player.show_deck(deck.playable_cards, deck.name)
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

  def reload_deck_menu
    deck_menu = NSApp.mainMenu.itemWithTitle :decks._
    deck_menu.submenu.removeAllItems

    item = NSMenuItem.alloc.initWithTitle(:deck_manager._, action: 'open_deck_manager:', keyEquivalent: 'm')
    deck_menu.submenu.addItem item
    item = NSMenuItem.alloc.initWithTitle(:reset._, action: 'reset:', keyEquivalent: 'r')
    deck_menu.submenu.addItem item
    item = NSMenuItem.alloc.initWithTitle(:save_all._, action: 'save_decks:', keyEquivalent: '')
    deck_menu.submenu.addItem item
    deck_menu.submenu.addItem NSMenuItem.separatorItem

    Deck.where(:is_active => true).sort_by(:name, :case_insensitive => true).each do |deck|
      item = NSMenuItem.alloc.initWithTitle(deck.name, action: 'open_deck:', keyEquivalent: '')
      deck_menu.submenu.addItem item
    end
  end

  def close_window_menu(enabled)
    window_menu = NSApp.mainMenu.itemWithTitle :window._
    close_window = window_menu.submenu.itemWithTitle :close._
    close_window.enabled = enabled
  end

  def performClose(_)
    if deck_manager
      deck_manager.window.performClose nil
    end
  end

  # restart HSTracker
  def applicationWillTerminate(_)
    if @app_will_restart
      app_path = NSBundle.mainBundle.bundlePath
      task = NSTask.new
      task.setLaunchPath '/usr/bin/open'
      task.setArguments [app_path]
      task.launch
    end
  end

  def applicationShouldTerminate(_)
    response = NSTerminateNow

    if deck_manager
      can_close = deck_manager.check_is_saved_on_close
      unless can_close
        response = NSTerminateCancel
      end
    end

    response
  end

  def debug(_)
    @debugger ||= Debugger.new
    @debugger.showWindow(nil)
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

      @downloader.close
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
