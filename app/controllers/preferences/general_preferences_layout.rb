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
    'ruRU' => 'ru_RU',
    'zhCN' => 'zh_CN',
    'zhTW' => 'zh_TW',
    'jaJP' => 'ja_JP'
  }

  KHSTrackerLocales = %w(de en fr it pt-br zh-cn es)

  def options
    {
      app_language: {
        label: :hstracker_language._,
        type: NSPopUpButton,
        init: -> (elem) {
          langs = NSUserDefaults.standardUserDefaults.objectForKey('AppleLanguages')
          current_locale = langs[0]

          KHSTrackerLocales.each do |loc|
            locale = NSLocale.alloc.initWithLocaleIdentifier loc
            display = locale.displayNameForKey(NSLocaleIdentifier, value: loc)

            item = NSMenuItem.alloc.initWithTitle(display.capitalize, action: nil, keyEquivalent: '')
            elem.menu.addItem item

            if current_locale == loc
              elem.selectItem item
            end
          end

          if current_locale.nil?
            elem.selectItemAtIndex -1
          end
        },
        changed: -> (elem) {
          choosen = elem.selectedItem.title

          KHSTrackerLocales.each do |loc|
            locale = NSLocale.alloc.initWithLocaleIdentifier loc
            display = locale.displayNameForKey(NSLocaleIdentifier, value: loc)

            if choosen == display.capitalize
              NSUserDefaults.standardUserDefaults.setObject([loc], forKey: 'AppleLanguages')
              NSNotificationCenter.defaultCenter.post('AppleLanguages_changed')
            end
          end
        }
      },
      hearthstone_locale: {
        label: :game_language._,
        type: NSPopUpButton,
        init: -> (elem) {
          current_locale = Configuration.hearthstone_locale

          KHearthstoneLocales.each do |hs_locale, osx_locale|
            locale = NSLocale.alloc.initWithLocaleIdentifier osx_locale
            display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale).titleize

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
        changed: -> (elem) {
          choosen = elem.selectedItem.title

          KHearthstoneLocales.each do |hs_locale, osx_locale|
            locale = NSLocale.alloc.initWithLocaleIdentifier osx_locale
            display = locale.displayNameForKey(NSLocaleIdentifier, value: osx_locale)

            if choosen == display.capitalize
              Configuration.hearthstone_locale = hs_locale
            end
          end
        }
      },
      reset_on_end: :reset_trackers_end._,
      show_notifications: :show_notifications._,
      remember_last_deck: :remember_last_deck._,
      log_path: {
        label: :log_path._,
        type: NSButton,
        init: -> (elem) {
          elem.title = Configuration.log_path
        },
        changed: -> (elem) {
          open_dialog = NSOpenPanel.openPanel
          open_dialog.setCanChooseDirectories(true)
          open_dialog.setAllowsMultipleSelection(false)
          open_dialog.setDirectoryURL(Configuration.log_path.nsurl)

          if open_dialog.runModal == NSOKButton
            url = open_dialog.URLs.first
            path = url.path

            Configuration.log_path = path
            elem.title = Configuration.log_path

            Hearthstone.instance.reboot
          end
        }

      }
      #prompt_deck: :detect_wrong_deck._
    }
  end

end
