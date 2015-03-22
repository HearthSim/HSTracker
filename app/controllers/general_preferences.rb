# General tab of the preferences
class GeneralPreferences < NSViewController
  KHearthstoneLocales = {
      'deDE' => 'de_DE',
      'enGB' => 'en_GB',
      'enUS' => 'en_US',
      'esES' => 'es_ES',
      'esMX' => 'es_MX',
      'frFR' => 'fr_FR',
      'itIT' => 'it_IT',
      'koKR' => 'ko_KR',
      'plPL' => 'pl_PL',
      'ptBR' => 'pt_BR',
      'ptPT' => 'pt_PT',
      'ruRU' => 'ru_RU',
      'zhCN' => 'zh_CN',
      'zhTW' => 'zh_TW'
  }

  KOnCardPlayedChoices = {
      :fade   => 'Fade',
      :remove => 'Remove'
  }

  def init
    super.tap do
      @layout   = GeneralPreferencesLayout.new
      self.view = @layout.view

      init_locales
      init_card_played
      @lock_windows = @layout.get(:lock_windows)
      @lock_windows.setAction 'lock_windows:'
      @lock_windows.setTarget self
    end
  end

  def view
    @layout.view
  end

  def init_locales

    current_locale = Configuration.locale
    @locale_popup  = @layout.get(:locale)
    KHearthstoneLocales.each do |hs_locale, osx_locale|
      locale  = NSLocale.alloc.initWithLocaleIdentifier osx_locale
      display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

      item = NSMenuItem.alloc.initWithTitle(display, action: nil, keyEquivalent: '')
      @locale_popup.menu.addItem item

      if current_locale == hs_locale
        @locale_popup.selectItem item
      end
    end

    if current_locale.nil?
      @locale_popup.selectItemAtIndex -1
    end

    @locale_popup.setAction 'locale_changed:'
    @locale_popup.setTarget self
  end

  def locale_changed(_)
    choosen = @locale_popup.selectedItem.title

    KHearthstoneLocales.each do |hs_locale, osx_locale|
      locale  = NSLocale.alloc.initWithLocaleIdentifier osx_locale
      display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

      if choosen == display
        Configuration.locale = hs_locale
      end
    end
  end

  def init_card_played

    current_choice     = Configuration.on_card_played
    @card_played_popup = @layout.get(:card_played)
    KOnCardPlayedChoices.each do |value, label|
      item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
      @card_played_popup.menu.addItem item

      if current_choice == value
        @card_played_popup.selectItem item
      end
    end

    @card_played_popup.setAction 'card_played_changed:'
    @card_played_popup.setTarget self
  end

  def card_played_changed(_)
    choosen = @card_played_popup.selectedItem.title

    KOnCardPlayedChoices.each do |value, label|
      if choosen == label
        Configuration.on_card_played = value
      end
    end
  end

  def lock_windows(_)
    Configuration.lock_windows = (@lock_windows.state == NSOnState)
    NSNotificationCenter.defaultCenter.post('lock_windows', Configuration.lock_windows)
  end

  # MASPreferencesViewController
  def identifier
    'GeneralPreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNamePreferencesGeneral)
  end

  def toolbarItemLabel
    'General'._
  end
end