class OpponentCardHud < Hud
  attr_accessor :position, :delegate, :card

  def initWithPosition(position)
    init.tap do
      @layout = OpponentCardHudLayout.new
      @layout.position = position
      self.position = position
      self.window = @layout.window
      self.window.delegate = self

      @label = @layout.get(:label)
      @label.delegate = self
    end
  end

  def set_level(level)
    window.setLevel level
  end

  def text=(text)
    @label.text = text
  end

  def resize_window_with_cards(card_count)
    frame = SizeHelper.opponent_card_hud_frame(position, card_count)
    return if frame.nil?
    self.window.setFrame(frame, display: true)
  end

  def window_locks
  end

  def window_transparency
  end

  def hover(_)
    self.delegate.hover_opponent_card(self) if self.delegate
  end

  def out(_)
    self.delegate.out_opponent_card(self) if self.delegate
  end

end
