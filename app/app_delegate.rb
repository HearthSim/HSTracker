class AppDelegate
  include CDQ

  Log = Motion::Log

  def applicationDidFinishLaunching(notification)
    cdq.setup

    # load cards into database if needed
    DatabaseGenerator.init_database

    # init logs
    Log.level = :debug

    Log.addLogger DDTTYLogger.sharedInstance

    file_logger = DDFileLogger.new
    file_logger.rollingFrequency = 60 * 60 * 12
    file_logger.logFileManager.maximumNumberOfLogFiles = 7
    Log.addLogger file_logger

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

    if Configuration.locale.nil?
      openPreferences(nil)
      return
    end

    Hearthstone.instance.listen(@player, :player)
    Hearthstone.instance.listen(@opponent, :opponent)

    if Hearthstone.instance.is_hearthstone_running?
      Hearthstone.instance.start
    end

    VersionChecker.check

    # TODO deck import from netdeck to be activated on deck creation will be available
    #check_clipboad_net_deck
  end

  def check_clipboad_net_deck
    Importer.netdeck

    Dispatch::Queue.main.after(2) do
      check_clipboad_net_deck
    end
  end

  # respond to the Import deck menu
  def import(_)
    @import = DeckImport.alloc.init
    @import.on_deck_loaded do |cards, clazz, name|
      Log.debug "#{clazz} / #{name}"

      if cards
        @player.cards = cards
      end
    end

    @player.window.beginSheet(@import.window, completionHandler: nil)
  end

  # preferences
  def preferences
    @preferences ||= begin
      general      = GeneralPreferences.alloc.init
      @preferences = MASPreferencesWindowController.alloc.initWithViewControllers([general], title: 'Preferences'._)
      @preferences
    end
  end

  def openPreferences(_)
    preferences.showWindow(nil)
  end
end
