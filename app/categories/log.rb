module Motion
  class Log

    def self.error(message)
      if OSXHelper.is_10_8?
        mp message
        return
      end
      __log(:error, message)
    end

    def self.warn(message)
      if OSXHelper.is_10_8?
        mp message
        return
      end
      __log(:warn, message)
    end

    def self.info(message)
      if OSXHelper.is_10_8?
        mp message
        return
      end
      __log(:info, message)
    end

    def self.debug(message)
      self.verbose(message)
    end

    def self.verbose(message)
      if OSXHelper.is_10_8?
        mp message
        return
      end
      __log(:verbose, message)
    end


  end
end
