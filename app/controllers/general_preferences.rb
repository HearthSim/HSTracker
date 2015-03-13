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

  def init
    super.tap do
      @layout   = GeneralPreferencesLayout.new
      self.view = @layout.view

      init_locales
    end
  end

  def view
    @layout.view
  end

  def init_locales

    current_locale = Configuration.locale || 'enUS'
    @locale_popup = @layout.get(:locale)
    KHearthstoneLocales.each do |hs_locale, osx_locale|
      locale  = NSLocale.alloc.initWithLocaleIdentifier osx_locale
      display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

      item = NSMenuItem.alloc.initWithTitle(display, action: nil, keyEquivalent: '')
      @locale_popup.menu.addItem item

      if current_locale == hs_locale
        @locale_popup.selectItem item
      end
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