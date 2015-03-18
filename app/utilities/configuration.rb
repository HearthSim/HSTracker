class Configuration

  # get the HS locale
  def self.locale
    NSUserDefaults.standardUserDefaults.objectForKey 'hearthstone_locale'
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