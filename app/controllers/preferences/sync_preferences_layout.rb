class SyncPreferencesLayout < PreferencesLayout

  def options
    {
      use_hearthstats: {
        type: NSButton,
        title: :configure_hearthstats._,
        init: -> (elem) {
          elem.buttonType = NSSwitchButton
          elem.state = (Configuration.use_hearthstats ? NSOnState : NSOffState)
        },
        changed: -> (elem) {
          Configuration.use_hearthstats = (elem.state == NSOnState)
          trigger :hearthstats_login, (elem.state == NSOnState)
        }
      }
    }
  end

end
