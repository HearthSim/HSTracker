module Observer

  def init_observers(&block)

    Hearthstone.instance.on(:app_running) do |is_running|
      log(:events, message: "Hearthstone is running?", is_running: is_running)
      if is_running && Configuration.size_from_game
        NSNotificationCenter.defaultCenter.post('resize_window')
      end
    end

    Hearthstone.instance.on(:app_activated) do |is_active|
      log(:events, message: "Hearthstone is active?", is_active: is_active)
      if is_active
        @player.set_level NSScreenSaverWindowLevel
        @opponent.set_level NSScreenSaverWindowLevel
        @timer_hud.set_level NSScreenSaverWindowLevel
      else
        @player.set_level NSNormalWindowLevel
        @opponent.set_level NSNormalWindowLevel
        @timer_hud.set_level NSNormalWindowLevel
      end
    end

    NSNotificationCenter.defaultCenter.observe 'size_from_game' do |_|
      menu = NSApp.mainMenu.itemWithTitle :window._
      lock = menu.submenu.itemWithTitle :lock_windows._
      unless lock
        lock = menu.submenu.itemWithTitle :unlock_windows._
      end
      lock.enabled = !Configuration.size_from_game
    end

    NSNotificationCenter.defaultCenter.observe 'deck_change' do |_|
      reload_deck_menu
    end

    NSNotificationCenter.defaultCenter.observe 'AppleLanguages_changed' do |_|
      response = NSAlert.alert(:language_change._,
                               buttons: [:ok._, :cancel._],
                               informative: :language_change_restart._)
      if response == NSAlertFirstButtonReturn
        @app_will_restart = true

        NSApplication.sharedApplication.terminate(nil)
        exit(0)
      end
    end

    NSNotificationCenter.defaultCenter.observe 'open_deck_manager' do |notif|
      open_deck_manager notif.userInfo
    end

    block.call if block
  end

end
