class SyncPreferencesLayout < PreferencesLayout

  def frame_size
    [[0, 0], [300, 350]]
  end

  def options
    {
        :use_hearthstats => {
            :type    => NSButton,
            :title   => 'Configure Hearthstats'._,
            :init    => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state      = (Configuration.use_hearthstats ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.use_hearthstats = (elem.state == NSOnState)
              trigger :hearthstats_login, (elem.state == NSOnState)
            }
        }
    }
  end

end