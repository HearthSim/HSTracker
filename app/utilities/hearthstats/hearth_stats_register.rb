class HearthStatsRegister < NSWindowController

  def init
    super.tap do
      @layout = HearthStatsRegisterLayout.new
      self.window = @layout.window

      @register = @layout.get(:register)
      @register.setTarget self
      @register.setAction 'register:'

      @cancel = @layout.get(:cancel)
      @cancel.setTarget self
      @cancel.setAction 'cancel:'
    end
  end

  def register(_)
    login = @layout.get(:login).stringValue
    confirm_login = @layout.get(:confirm_login).stringValue
    password = @layout.get(:password).stringValue
    confirm_password = @layout.get(:confirm_password).stringValue

    if login != confirm_login
      NSAlert.alert('Login are not the same'._,
                    buttons: ['OK'._],
                    window: self.window)
      return
    end

    if password != confirm_password
      NSAlert.alert('Password are not the same'._,
                    buttons: ['OK'._],
                    window: self.window)
      return
    end

    HearthStatsAPI.register(login, password) do |success, result|
      if success
        message = 'Registration successfully completed'
        @register.title = 'Close'._
        @register.setAction 'close:'
        @cancel.hidden = true
      else
        message = []
        if result
          if result.has_key? 'email'
            message << "#{'Login'._} : #{result['email'].join(',')}"
          end
          if result.has_key? 'password'
            message << "#{'Password'._} : #{result['password'].join(',')}"
          end
        end
        message = message.join("\n")
      end

      NSAlert.alert(message._,
                    buttons: ['OK'._],
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
end
