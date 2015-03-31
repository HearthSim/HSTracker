class Configuration

  class << self

    def is_cyrillic_or_asian
      locale =~ /^(zh|ko|ru)/
    end

    KValidOptions = %w(hearthstone_locale card_played windows_locked window_transparency
                  flash_color fixed_window_names one_line_count reset_on_end card_layout)

    KDefaults = {
        :flash_color         => [55, 189, 223],
        :window_transparency => 0.1,
        :card_played         => :fade,
        :card_layout         => :big
    }

    def method_missing(symbol, *args)
      is_add = symbol =~ /.+=$/
      method = symbol.gsub(/=$/, '')

      unless KValidOptions.include? method
        raise "#{symbol} is not a valid option"
      end

      if is_add
        value = args[0]
        NSUserDefaults.standardUserDefaults.setObject(value, forKey: method)

        # always post an event with this key...
        # we don't care if nobody is listening
        NSNotificationCenter.defaultCenter.post(method)
      else
        value = NSUserDefaults.standardUserDefaults.objectForKey(method)
        if KDefaults[method.to_sym] and value.nil?
          value = KDefaults[method.to_sym]
        end

        # special cases
        case method
          when 'flash_color'
            value = value.nscolor
          when 'card_played', 'card_layout'
            value = value.to_sym unless value.is_a? Symbol
        end

        value
      end
    end

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
  end

end