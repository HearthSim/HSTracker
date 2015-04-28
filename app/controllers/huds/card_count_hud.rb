class CardCountHud < Hud
  def initWithPlayer(player)
    init.tap do
      @layout              = CardCountHudLayout.new
      @layout.player       = player
      self.window          = @layout.window
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
end