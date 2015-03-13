class Configuration

  # get the HS locale
  def self.locale
    NSUserDefaults.standardUserDefaults.objectForKey 'hearthstone_locale'
  end

  # set the HS locale
  def self.locale=(value)
    NSUserDefaults.standardUserDefaults.setObject(value, forKey: 'hearthstone_locale')
  end

end