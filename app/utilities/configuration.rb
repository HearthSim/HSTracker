class Configuration

  class << self
    # get the HS locale
    def locale
      locale = NSUserDefaults.standardUserDefaults.objectForKey 'hearthstone_locale'
      return locale unless locale.nil?

      current = NSLocale.currentLocale.localeIdentifier
      case current
        when /^fr/
          'frFR'
        when /^ru/
          'ruRU'
        when /^de/
          'deDE'
        when /^es/
          'esES'
        when /^it/
          'itIT'
        when /^ko/
          'koKR'
        when /^pl/
          'plPL'
        when /^pt/
          'ptPT'
        when /^zh/
          'zhCN'
        else
          'enUS'
      end
    end

    # set the HS locale
    def locale=(value)
      NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'hearthstone_locale')
    end

    def is_cyrillic_or_asian
      locale =~ /^(zh|ko|ru)/
    end

    def on_card_played
      played = NSUserDefaults.standardUserDefaults.objectForKey 'card_played'
      if played
        return played.to_sym
      end
      :fade
    end

    def on_card_played=(value)
      NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'card_played')
    end

    def lock_windows
      NSUserDefaults.standardUserDefaults.objectForKey('windows_locked')
    end

    def lock_windows=(value)
      NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'windows_locked')
      NSNotificationCenter.defaultCenter.post('lock_windows')
    end

    def window_transparency
      NSUserDefaults.standardUserDefaults.objectForKey('window_transparency') || 0.1
    end

    def window_transparency=(value)
      NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'window_transparency')
      NSNotificationCenter.defaultCenter.post('window_transparency')
    end

    def flash_color
      (NSUserDefaults.standardUserDefaults.objectForKey('flash_color') || [55, 189, 223]).nscolor
    end

    def flash_color=(value)
      NSUserDefaults.standardUserDefaults.setObject(value.hex, forKey: 'flash_color')
      NSNotificationCenter.defaultCenter.post('flash_color')
    end

    def fixed_window_names
      NSUserDefaults.standardUserDefaults.objectForKey('fixed_window_names')
    end

    def fixed_window_names=(value)
      NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'fixed_window_names')
    end

  end

end