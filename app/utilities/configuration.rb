class Configuration

  class << self

    def reset
      domain = NSBundle.mainBundle.bundleIdentifier
      NSUserDefaults.standardUserDefaults.removePersistentDomainForName(domain)
    end

    def is_cyrillic_or_asian
      hearthstone_locale =~ /^(zh|ko|ru|ja)/
    end

    KValidOptions = %w(hearthstone_locale card_played windows_locked window_transparency
                  flash_color fixed_window_names reset_on_end card_layout count_color
                  count_color_border hand_count_window show_get_cards show_card_on_hover
                  in_hand_as_played use_hearthstats hearthstats_token show_notifications
                  remember_last_deck last_deck_played skin show_timer show_opponent_tracker
                  prompt_deck size_from_game log_path rarity_colors opponent_overlay
                  show_one_card)

    KDefaults = {
      flash_color: [55, 189, 223],
      count_color: [255, 255, 255],
      count_color_border: [0, 0, 0],
      window_transparency: 0.1,
      card_played: :fade,
      card_layout: :big,
      windows_locked: false,
      fixed_window_names: false,
      reset_on_end: false,
      show_get_cards: false,
      hand_count_window: :tracker,
      show_card_on_hover: true,
      in_hand_as_played: false,
      use_hearthstats: false,
      show_notifications: true,
      remember_last_deck: true,
      skin: :hearthstats,
      show_timer: true,
      show_opponent_tracker: true,
      prompt_deck: true,
      size_from_game: false,
      log_path: '/Applications/Hearthstone/Logs/',
      rarity_colors: true,
      opponent_overlay: true,
      show_one_card: false,
    }

    def method_missing(symbol, *args)
      is_add = symbol =~ /.+=$/
      method = symbol.gsub(/=$/, '')

      unless KValidOptions.include? method
        raise ArgumentError, "#{symbol} is not a valid option", caller
      end

      if is_add
        value = args[0]
        # special cases
        case method
          when 'flash_color', 'count_color', 'count_color_border'
            value = value.hex
        end

        NSUserDefaults.standardUserDefaults.setObject(value, forKey: method)
        NSUserDefaults.standardUserDefaults.synchronize

        # always post an event with this key...
        # we don't care if nobody is listening
        NSNotificationCenter.defaultCenter.post(method)
      else
        value = NSUserDefaults.standardUserDefaults.objectForKey(method)

        if KDefaults.has_key?(method.to_sym) && value.nil?
          value = KDefaults.fetch(method.to_sym)
        end

        # special cases
        case method
          when 'flash_color', 'count_color', 'count_color_border'
            value = value.nscolor
          when 'card_played', 'card_layout', 'one_line_count', 'hand_count_window', 'skin'
            value = value.to_sym unless value.is_a? Symbol
        end

        value
      end
    end

    # get the HS locale
    def hearthstone_locale
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

  end

end
