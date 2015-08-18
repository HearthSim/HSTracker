class HearthStatsLogin < NSWindowController
  def init
    super.tap do
      @layout = HearthStatsLoginLayout.new
      self.window = @layout.window

      @connect = @layout.get(:connect)
      @connect.setTarget self
      @connect.setAction 'connect:'

      @cancel = @layout.get(:cancel)
      @cancel.setTarget self
      @cancel.setAction 'cancel:'

      @register = @layout.get(:register)
      @register.setTarget self
      @register.setAction 'register:'
    end
  end

  def connect(_)
    login = @layout.get(:login).stringValue
    password = @layout.get(:password).stringValue

    HearthStatsAPI.login(login, password) do |success, auth_token|
      if success
        Configuration.hearthstats_token = auth_token

        message = 'Login successfully'

        @connect.title = :close._
        @connect.setAction 'close:'
        @cancel.hidden = true
      else
        message = 'Login Error'
      end

      NSAlert.alert(message._,
                    buttons: [:ok._],
                    window: self.window
      )
    end
  end

  def close(_)
    self.window.close
  end

  def cancel(_)
    Configuration.hearthstats_token = nil
    Configuration.use_hearthstats = false
    self.window.close
  end

  def register(_)
    @register_window = HearthStatsRegister.new
    @register_window.showWindow(nil)
  end
end
