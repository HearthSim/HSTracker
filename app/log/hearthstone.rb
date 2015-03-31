class Hearthstone

  # used when debugging from actual log file
  KDebugFromFile = false

  Log = Motion::Log

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def is_started
    @is_started ||= false
  end

  # get the path to the log.config
  def self.config_path
    '/Library/Preferences/Blizzard/Hearthstone/log.config'.home_path
  end

  # get log.config in bundle
  def self.new_config_path
    'files/log.config'.resource_path
  end

  # get the path to the player.log
  def self.log_path
    '/Library/Logs/Unity/Player.log'.home_path
  end

  # check if HS is running
  def is_hearthstone_running?
    NSWorkspace.sharedWorkspace.runningApplications.each do |app|
      if app.localizedName == 'Hearthstone'
        return true
      end
    end

    # debugging from actual log file, fake HS is running
    if KDebugFromFile
      true
    else
      false
    end
  end

  def reset
    @log_analyzer.reset_data
  end

  # register events
  def on(event, &block)
    @listeners[event] ||= []

    @listeners[event] << (block.respond_to?('weak!') ? block.weak! : block)

    if event == :app_running
      # if this this the app_running event, call it now
      block.call(is_hearthstone_running?)
    end
  end

  # register a listener for the log parsing
  # who can be either
  # :player -> listen only for player events
  # :opponent -> listen only for opponent events
  # : all -> listen all events
  def listen(listener, who)
    @listeners[who] ||= []
    @listeners[who] << listener
  end

  # start the analysis if HS is running
  def start
    if is_hearthstone_running?
      start_tracking
    end
  end

  private
  def initialize
    super.tap do
      @update_list = []
      @listeners   = {}
      setup
      listener
    end
  end

  # retrieve an array interested by the events for the "type" player
  # all are always added
  def listeners(type = nil)
    all = []
    if type and @listeners[type]
      all += @listeners[type]
    elsif type.nil?
      all += @listeners[:player] if @listeners[:player]
      all += @listeners[:opponent] if @listeners[:opponent]
    end
    all += @listeners[:all] if @listeners[:all]

    all
  end

  # write the log.config file is not exists
  def setup
    unless Hearthstone.config_path.file_exists?
      content = File.read(Hearthstone.new_config_path)
      dir     = File.dirname(Hearthstone.config_path)

      NSFileManager.defaultManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil, error: nil)
      File.open(Hearthstone.config_path, 'w') { |file| file.write(content) }
    end
  end

  # observe for HS starting/leaving
  def listener
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector: 'workspaceDidLaunchApplication:', name: NSWorkspaceDidLaunchApplicationNotification, object: nil)
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector: 'workspaceDidTerminateApplication:', name: NSWorkspaceDidTerminateApplicationNotification, object: nil)
  end

  # check if the app launched is HS
  def workspaceDidLaunchApplication(notification)
    application = notification.userInfo.fetch('NSWorkspaceApplicationKey', nil)

    if application && application.localizedName == 'Hearthstone'
      start_tracking

      if @listeners[:app_running]
        @listeners[:app_running].each do |block|
          block.call(true) if block
        end
      end
    end
  end

  # chec if the app terminated is HS
  def workspaceDidTerminateApplication(notification)
    application = notification.userInfo.fetch('NSWorkspaceApplicationKey', nil)

    if application && application.localizedName == 'Hearthstone'
      stop_tracking

      if @listeners[:app_running]
        @listeners[:app_running].each do |block|
          block.call(false) if block
        end
      end
    end
  end

  # start analysis and dispatch events
  def start_tracking
    return if is_started
    @is_started = true

    @log_observer = LogObserver.new
    @log_analyzer = LogAnalyzer.new

    # game finish
    @log_analyzer.on_game_end do |player|
      listeners.each do |listener|
        listener.game_end(player) if listener.respond_to?('game_end')
      end
    end

    # game start
    @log_analyzer.on_game_start do
      listeners.each do |listener|
        listener.game_start if listener.respond_to?('game_start')
      end
    end

    # hero
    @log_analyzer.on_hero do |player, hero_id|
      listeners(player).each do |listener|
        listener.set_hero(player, hero_id) if listener.respond_to?('set_hero')
      end
    end

    # coin
    @log_analyzer.on_coin do |player|
      listeners(player).each do |listener|
        listener.get_coin(player) if listener.respond_to?('get_coin')
      end
    end

    # cards
    @log_analyzer.on_card(:draw_card) do |player, card_id|
      listeners(player).each do |listener|
        listener.draw_card card_id if listener.respond_to?('draw_card')
      end
    end

    @log_analyzer.on_card(:return_deck_card) do |player, card_id|
      listeners(player).each do |listener|
        listener.restore_card card_id if listener.respond_to?('restore_card')
      end
    end

    @log_analyzer.on_card(:discard_card) do |player, card_id|
      listeners(player).each do |listener|
        listener.discard_card card_id if listener.respond_to?('discard_card')
      end
    end

    @log_analyzer.on_card(:card_stolen) do |player, card_id|
      listeners(player).each do |listener|
        listener.card_stolen card_id if listener.respond_to?('card_stolen')
      end
      end

    @log_analyzer.on_card(:play_secret) do
      listeners(:opponent).each do |listener|
        listener.play_secret if listener.respond_to?('play_secret')
      end
    end

    @log_analyzer.on_card(:secret_revealed) do |player, card_id|
      listeners(player).each do |listener|
        listener.secret_revealed(card_id) if listener.respond_to?('secret_revealed')
      end
    end

    @log_analyzer.on_card(:play_card) do |player, card_id|
      listeners(player).each do |listener|
        listener.play_card card_id if listener.respond_to?('play_card')
      end
    end

    @log_analyzer.on_card(:return_hand_card) do |player, card_id|

    end

    @log_analyzer.on_player_name do |player, name|

    end

    @log_observer.on_read_line do |line|
      @log_analyzer.analyze(line)
    end

    @log_observer.start
  end

  # stop analysis
  def stop_tracking
    @is_started = false

    @log_observer.stop
    @log_observer = nil
    @log_analyzer = nil
  end

end