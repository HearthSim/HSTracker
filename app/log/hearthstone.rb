class Hearthstone

  attr_accessor :log_observer, :hearthstats_token

  # used when debugging from actual log file
  KDebugFromFile = false

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def is_started?
    @is_started ||= false
  end

  def is_active?
    @is_active ||= false
  end

  # get the path to the log.config
  def self.config_path
    '/Library/Preferences/Blizzard/Hearthstone/log.config'.home_path
  end

  # get the path to the player.log
  def self.log_path
    '/Library/Logs/Unity/Player.log'.home_path
  end

  # check if HS is running
  def is_hearthstone_running?
    app = NSWorkspace.sharedWorkspace.runningApplications.find {|app| app.localizedName == 'Hearthstone' }
    return true if app

    # debugging from actual log file, fake HS is running
    if KDebugFromFile
      true
    else
      false
    end
  end

  def reset
    @log_observer.reset_data if @log_observer
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

  def start_from_debugger(text)
    start_tracking(text)
  end

  private
  def initialize
    super.tap do
      @update_list = []
      @listeners = {}
      setup
      listener
    end
  end

  # retrieve an array interested by the events for the "type" player
  # all are always added
  def listeners(type = nil)
    all = []
    if type && @listeners[type]
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
    zones = %w(Zone Bob Power Asset Rachelle Arena)

    config_changed = false
    unless Dir.exists?(File.dirname(Hearthstone.config_path))
      Dir.mkdir(File.dirname(Hearthstone.config_path))
      config_changed = true
    end

    if !Hearthstone.config_path.file_exists?
      File.open(Hearthstone.config_path, 'w') do |f|
        zones.each do |zone|
          f << "[#{zone}]\n"
					f << "LogLevel=1\n"
					f << "FilePrinting=false\n"
					f << "ConsolePrinting=true\n"
					f << "ScreenPrinting=false\n"
        end
      end
      config_changed = true
    else
      zones_found = []
      File.open(Hearthstone.config_path, 'r+') do |f|
        zones.each do |zone|
          found = f.find { |l| l =~ /\[#{zone}\]/ }
          zones_found << zone if found
        end

        missings = zones - zones_found
        unless missings.empty?
          missings.each do |zone|
            f << "\n[#{zone}]"
  					f << "\nLogLevel=1"
  					f << "\nFilePrinting=false"
  					f << "\nConsolePrinting=true"
  					f << "\nScreenPrinting=false"
          end
        end
        config_changed = true
      end
    end

    if config_changed && is_hearthstone_running?
      NSAlert.alert(:alert._,
                    buttons: [:ok._],
                    informative: :restart_hearthstone_logs._)

    end
  end

  # observe for HS starting/leaving
  def listener
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector: 'app_launched:', name: NSWorkspaceDidLaunchApplicationNotification, object: nil)
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector: 'app_terminated:', name: NSWorkspaceDidTerminateApplicationNotification, object: nil)
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector: 'app_activated:', name: NSWorkspaceDidActivateApplicationNotification, object: nil)
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector: 'app_deactivated:', name: NSWorkspaceDidDeactivateApplicationNotification, object: nil)
  end

  # check if the app launched is HS
  def app_launched(notification)
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

  # check if the app terminated is HS
  def app_terminated(notification)
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

  # check if the activated app is HS
  def app_activated(notification)
    application = notification.userInfo.fetch('NSWorkspaceApplicationKey', nil)

    if application && application.localizedName == 'Hearthstone'
      @is_active = true
      if @listeners[:app_activated]
        @listeners[:app_activated].each do |block|
          block.call(true) if block
        end
      end
    end
  end

  # check if the deactivated app is HS
  def app_deactivated(notification)
    application = notification.userInfo.fetch('NSWorkspaceApplicationKey', nil)

    if application && application.localizedName == 'Hearthstone'
      @is_active = false
      if @listeners[:app_activated]
        @listeners[:app_activated].each do |block|
          block.call(false) if block
        end
      end
    end
  end

  # start analysis and dispatch events
  def start_tracking(text=nil)
    return if is_started?
    @is_started = true

    @log_observer = LogObserver.new
    @log_observer.start
    if text
      @log_observer.debug(text)
    end
  end

  # stop analysis
  def stop_tracking
    @is_started = false

    if @log_observer
      @log_observer.stop
      @log_observer = nil
    end
  end

end
