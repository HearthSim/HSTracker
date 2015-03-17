class AppDelegate
  include CDQ

  Log = Motion::Log

  def applicationDidFinishLaunching(notification)
    cdq.setup

    show_splash_screen

    # init logs
    Log.level = :debug

    Log.addLogger DDTTYLogger.sharedInstance

    file_logger                                        = DDFileLogger.new
    file_logger.rollingFrequency                       = 60 * 60 * 12
    file_logger.logFileManager.maximumNumberOfLogFiles = 7
    Log.addLogger file_logger

    # load cards into database if needed
    DatabaseGenerator.init_database do
      @splash.window.orderOut(self)

      Hearthstone.instance.on(:app_running) do |is_running|
        Log.info "Hearthstone is running? #{is_running}"
      end

      NSApp.mainMenu = MainMenu.new.menu

      @player = PlayerTracker.alloc.init
      @player.showWindow(self)
      @player.window.orderFrontRegardless

      @opponent = OpponentTracker.alloc.init
      @opponent.showWindow(self)
      @opponent.window.orderFrontRegardless

      # test if locale is set
      if Configuration.locale.nil?
        openPreferences(nil)
        next
      end

      Hearthstone.instance.listen(@player, :player)
      Hearthstone.instance.listen(@opponent, :opponent)

      if Hearthstone.instance.is_hearthstone_running?
        Hearthstone.instance.start
      end

      VersionChecker.check
    end
  end

  def show_splash_screen
    @splash = LoadingScreen.alloc.init
    @splash.showWindow(nil)
  end

  # preferences
  def preferences
    @preferences ||= begin
      general = GeneralPreferences.alloc.init
      MASPreferencesWindowController.alloc.initWithViewControllers([general], title: 'Preferences'._)
    end
  end

  def openPreferences(_)
    preferences.showWindow(nil)
  end

  # deck manager
  def deck_manager
    @deck_manager ||= begin
      manager                 = DeckManager.alloc.init
      manager.window.delegate = self
      manager
    end
  end

  def open_deck_manager(_)
    # change windows level
    @player.window.setLevel NSNormalWindowLevel
    @opponent.window.setLevel NSNormalWindowLevel

    deck_manager.showWindow(nil)
    deck_manager.player_view = @player
  end

  # nswindowdelegate
  def windowShouldClose(sender)
    deck_manager.check_is_saved_on_close
  end

  def windowWillClose(notification)
    # change windows level back
    @player.window.setLevel NSScreenSaverWindowLevel
    @opponent.window.setLevel NSScreenSaverWindowLevel
  end
end
