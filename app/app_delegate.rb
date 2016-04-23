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
      if Store[:migrate_to_016].nil?
        Store[:migrate_to_016] = true
        response = NSAlert.alert("Upgrade",
                               buttons: ["Upgrade", "Keep"],
                               informative: "Your version of HSTracker is now obsolete and replaced by a new one.\nTo upgrade to this version, please use the 'Upgrade' button.\nYour data will be saved and you will be prompted to download the following release after that.\nWARNING: If you are on 0SX 10.8 or 10.9, you will have to keep this version (choose the 'Keep' button)"
                               )
        if response == NSAlertFirstButtonReturn
          migrate
          return
        end
      end

      build_ui
    end

  end

  def migrate
    # init hstracker 0.16 dir
    appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
    path = "#{appSupport.first}/HSTracker/decks"
    NSFileManager.defaultManager.createDirectoryAtPath(path,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil,
                                                         error: nil)
    file = "#{path}/decks.json"
    splash_screen.window.orderOut(self)

    # export all decks as json
    backup = []
    Deck.each do |deck|
      json_deck = {
        name: deck.name,
        playerClass: deck.player_class,
        isArena: deck.arena,
        version: deck.version.to_s,
        isActive: deck.is_active,
        hearthstatsId: deck.hearthstats_id,
        hearthstatsVersionId: deck.hearthstats_version_id,
        creationDate: NSDate.date.timeIntervalSince1970,
        deckId: "#{NSUUID.new.UUIDString}-#{NSDate.date.timeIntervalSince1970}",
        statistics: [],
        cards: {}
      }

      deck.cards.to_a.each do |card|
        json_deck[:cards][card.card_id] = card.count
      end

      deck.statistics.to_a.each do |stat|
        next if stat.opponent_class.nil?

        json_deck[:statistics] << {
          playerRank: stat.rank,
          numTurns: stat.turns,
          date: stat.created_at.timeIntervalSince1970,
          hasCoin: stat.has_coin ? 1 : 0,
          gameResult: stat.win ? 1 : 2,         # (0 = Unknow, 1= Win, 2 = Loss, 3 = Draw)
          opponentName: stat.opponent_name,
          cards: {},
          playerMode: 1,         # (1 = Ranked, 2 = Casual, 3 = Arena, 4 = Brawl)
          opponentClass: stat.opponent_class.lowercaseString,
          duration: stat.duration
        }
      end

      backup << json_deck
    end

    # save json
    json = JSON.generate(backup)
    json.write_to(file)

    # tell about the new version !
    NSAlert.alert("Upgrade",
                  buttons: ["Continue"],
                  informative: "Your data has been migrated with success.\nPlease click continue to open your browser on the new download link !\nHSTracker will close."
                  )
    NSWorkspace.sharedWorkspace.openURL 'https://rink.hockeyapp.net/apps/2f0021b9bb1842829aa1cfbbd85d3bed'.nsurl
    exit
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
