class CardCountHud < Hud

  def initWithPlayer(player)
    init.tap do
      @layout = CardCountHudLayout.new
      @layout.player = player
      @player = player
      self.window = @layout.window
      self.window.delegate = self

      @label = @layout.get(:label)
    end
  end

  def card_layout
    @label.setNeedsDisplay true
  end

  def text=(text)
    @label.text = text
  end

  def resize_window
    frame = @player == :player ? SizeHelper.player_card_count_frame : SizeHelper.opponent_card_count_frame
    return if frame.nil?
    self.window.setFrame(frame, display: true)
  end
end
