class TimerHud < Hud

  def init
    super.tap do
      @layout = TimerHudLayout.new
      self.window = @layout.window
      self.window.delegate = self

      @label = @layout.get(:label)

      NSNotificationCenter.defaultCenter.observe('show_timer') do |_|
        show_hide
      end
    end
  end

  def set_level(level)
    window.setLevel level
  end

  def show_hide
    if Configuration.show_timer
      self.window.orderFront(self)
    else
      self.window.orderOut(self)
    end
  end

  def game_start
    @label.text = nil
    @player_mulligan = @opponent_mulligan = false
  end

  def game_end
    @label.text = nil
    if @timer
      @timer.invalidate
    end
  end

  def mulligan_done(who)
    who == :player ? @player_mulligan = true : @opponent_mulligan = true
  end

  def restart(player)
    return unless Configuration.show_timer

    @current_player = player

    if @timer
      @timer.invalidate
    end
    @seconds = 90
    @timer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                    target: self,
                                                    selector: 'fire:',
                                                    userInfo: nil,
                                                    repeats: true)

    if (!@player_mulligan && @opponent_mulligan) || (!@opponent_mulligan && @player_mulligan) || (!@player_mulligan && !@opponent_mulligan && @seconds < 85)
      @opponent_mulligan = @player_mulligan = true
    end

  end

  def resize_window
    frame = SizeHelper.timer_hud_frame
    return if frame.nil?
    self.window.setFrame(frame, display: true)
  end

  private
  def fire(_)
    @seconds -= 1 if @seconds > 0

    return if !@player_mulligan && !@opponent_mulligan

    seconds = 90 - @seconds
    if @seconds < 10
      @label.flash
    end

    @label.text = '%02d:%02d' % [(seconds / 60) % 60, seconds % 60]
  end

end
