class LanguageChooseScreen < ProMotion::WindowScreen
  stylesheet LanguageChooseScreenStylesheet

  def on_load
    append(NSTextField, :app_language)
    append(NSPopUpButton, :app_language_choice).on(:change) do
      enable_save
    end

    append(NSTextField, :hs_language)
    append(NSPopUpButton, :hs_language_choice).on(:change) do
      enable_save
    end

    append(NSButton, :save).on(:click) do
      mp hearthstone_locale: find(:hs_language_choice).data,
         app_language: find(:app_language_choice).data

      hs_language = Constants::KHearthstoneLocales.select do |loc|
        locale = NSLocale.alloc.initWithLocaleIdentifier loc
        find(:hs_language_choice).data == locale.displayNameForKey(NSLocaleIdentifier, value: loc).titleize
      end.first

      app_language = Constants::KHSTrackerLocales.select do |loc|
        locale = NSLocale.alloc.initWithLocaleIdentifier loc
        find(:app_language_choice).data == locale.displayNameForKey(NSLocaleIdentifier, value: loc).titleize
      end.first

      mp app_language: app_language,
         hs_language: hs_language
      Store[:hearthstone_locale] = hs_language
      Store['AppleLanguages'] = [app_language]
      @on_save.call if @on_save
    end
  end

  def enable_save
    find(:save).style do |st|
      hs_language = find(:hs_language_choice).data
      app_language = find(:app_language_choice).data

      st.enabled = !hs_language.nil? && hs_language != :game_language._ &&
        !app_language.nil? && app_language != :hstracker_language._
    end
  end

  def on_save(&block)
    @on_save = block
  end

  def window_frame
    width = LanguageChooseScreenStylesheet::KWidth
    height = LanguageChooseScreenStylesheet::KHeight

    [HSTrackerStylesheet.center_in_screen(width, height), [width, height]]
  end

end

