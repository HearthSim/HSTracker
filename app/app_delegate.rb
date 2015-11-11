class AppDelegate
  include CDQ
  include Database
  include Menu
  include Observer
  include Ui

  def applicationDidFinishLaunching(notification)
    # Starting hockey
    if RUBYMOTION_ENV == 'release'
      BITHockeyManager.sharedHockeyManager.configureWithIdentifier(ENV['hockey_app_id'], delegate: self)
      BITHockeyManager.sharedHockeyManager.startManager
    end

    return true if RUBYMOTION_ENV == 'test'

    #AFNetworkActivityLogger.sharedLogger.startLogging

    init_database do
      build_ui
    end

  end

  def build_ui
    Dispatch::Queue.main.async do
      splash_screen.text(:loading._(name: :interface._))
    end
    load_windows do
      build_observers
    end
  end

  def build_observers
    Dispatch::Queue.main.async do
      splash_screen.text(:loading._(name: :observers._))
    end
    init_observers do
      load_configuration
    end
  end

  def load_configuration
    Dispatch::Queue.main.async do
      splash_screen.text(:loading._(name: :configuration._))
    end

    if Configuration.remember_last_deck
      last_deck_played = Configuration.last_deck_played
      unless last_deck_played.nil?
        name, version = last_deck_played.split('#')
        deck = Deck.where(name: name).and(:version).eq(version).first
        if deck
          @player.show_deck(deck.playable_cards, deck.name)
          Game.instance.with_deck(deck)
        end
      end
    end

    Configuration.use_hearthstats = !Configuration.hearthstats_token.nil?

    splash_screen.window.orderOut(self)

    if ImageCache.need_download?
      ask_download_images(nil)
    elsif Hearthstone.instance.is_hearthstone_running?
      Dispatch::Queue.main.after(1) do
        Hearthstone.instance.reset
      end
    end

  end

  def splash_screen
    @splash ||= begin
      splash = LoadingScreen.new
      splash.showWindow(nil)
      splash
    end
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

  # deck manager
  def deck_manager
    @deck_manager ||= begin
      manager = DeckManager.new
      manager.window.delegate = self
      manager
    end
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

  # hockey
  def applicationLogForCrashManager(manager)
    log_file_content
  end

end
