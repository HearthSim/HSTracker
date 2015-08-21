module Ui

  def load_windows(&block)
    NSApp.mainMenu = MainMenu.new.menu

    @player = PlayerTracker.new
    @player.showWindow(self)
    @player.window.orderFrontRegardless

    @opponent = OpponentTracker.new
    if Configuration.show_opponent_tracker
      @opponent.showWindow(self)
      @opponent.window.orderFrontRegardless
    end

    @timer_hud = TimerHud.new
    if Configuration.show_timer
      @timer_hud.showWindow(self)
    end

    Game.instance.player_tracker = @player
    Game.instance.opponent_tracker = @opponent
    Game.instance.timer_hud = @timer_hud

    block.call if block
  end
end
