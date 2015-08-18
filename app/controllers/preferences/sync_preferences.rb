class SyncPreferences < NSViewController

  def init
    super.tap do
      @layout = SyncPreferencesLayout.new
      self.view = @layout.view

      @layout.on :hearthstats_login do |status|
        hearthstats_login(status)
      end
    end
  end

  def view
    @layout.view
  end

  # MASPreferencesViewController
  def identifier
    'SyncPreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNameUserAccounts)
  end

  def toolbarItemLabel
    :user_accounts._
  end

  def hearthstats_login(status)
    if status
      @config = HearthStatsLogin.new
      @config.window.delegate = self
      @config.showWindow(nil)
    else
      Configuration.hearthstats_token = nil
    end
  end
end
