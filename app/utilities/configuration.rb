class Configuration

  class << self

    def reset
      domain = NSBundle.mainBundle.bundleIdentifier
      NSUserDefaults.standardUserDefaults.removePersistentDomainForName(domain)
    end

    def is_cyrillic_or_asian
      hearthstone_locale =~ /^(zh|ko|ru)/
    end

    KValidOptions = %w(hearthstone_locale card_played windows_locked window_transparency
                  flash_color fixed_window_names one_line_count reset_on_end card_layout)

    KDefaults = {
        :flash_color         => [55, 189, 223],
        :window_transparency => 0.1,
        :card_played         => :fade,
        :card_layout         => :big,
        :one_line_count      => :window_one_line,
        :windows_locked      => false,
        :fixed_window_names  => false,
        :reset_on_end        => false
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
          when 'flash_color'
            value = value.hex
        end

        NSUserDefaults.standardUserDefaults.setObject(value, forKey: method)
        NSUserDefaults.standardUserDefaults.synchronize

        # always post an event with this key...
        # we don't care if nobody is listening
        NSNotificationCenter.defaultCenter.post(method)
      else
        value = NSUserDefaults.standardUserDefaults.objectForKey(method)

        if KDefaults.has_key?(method.to_sym) and value.nil?
          value = KDefaults.fetch(method.to_sym)
        end

        # special cases
        case method
          when 'flash_color'
            value = value.nscolor
          when 'card_played', 'card_layout', 'one_line_count'
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