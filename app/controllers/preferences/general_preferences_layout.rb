class GeneralPreferencesLayout < PreferencesLayout

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

  def options
    {
        :locale => {
            :label => 'Game language'._,
            :type  => NSPopUpButton,
            :init => -> (elem) {
              current_locale = Configuration.locale

              KHearthstoneLocales.each do |hs_locale, osx_locale|
                locale  = NSLocale.alloc.initWithLocaleIdentifier osx_locale
                display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

                item = NSMenuItem.alloc.initWithTitle(display, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_locale == hs_locale
                  elem.selectItem item
                end
              end

              if current_locale.nil?
                elem.selectItemAtIndex -1
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KHearthstoneLocales.each do |hs_locale, osx_locale|
                locale  = NSLocale.alloc.initWithLocaleIdentifier osx_locale
                display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

                if choosen == display
                  Configuration.locale = hs_locale
                end
              end
            }
        },
        :card_played => {
            :label => 'Card played'._,
            :type  => NSPopUpButton,
            :init => -> (elem) {
              current_choice     = Configuration.card_played

              KOnCardPlayedChoices.each do |value, label|
                item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_choice == value
                  elem.selectItem item
                end
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KOnCardPlayedChoices.each do |value, label|
                if choosen == label
                  Configuration.card_played = value
                end
              end
            }
        },
        :reset_on_end        => {
            :type    => NSButton,
            :title   => 'Reset trackers on game end'._,
            :init    => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state      = (Configuration.reset_on_end ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.reset_on_end = (elem.state == NSOnState)
            }
        }
    }
  end

end