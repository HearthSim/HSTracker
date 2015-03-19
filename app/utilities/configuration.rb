class Configuration

  # get the HS locale
  def self.locale
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
  def self.locale=(value)
    NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'hearthstone_locale')
  end

  def self.on_card_played
    played = NSUserDefaults.standardUserDefaults.objectForKey 'card_played'
    if played
      return played.to_sym
    end
    :fade
  end

  def self.on_card_played=(value)
    NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'card_played')
  end

end