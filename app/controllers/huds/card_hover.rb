class CardHover < Hud

  def init
    super.tap do
      @layout              = CardHoverLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @label = @layout.get(:label)
    end
  end

  def clear
    @label.text = nil
  end

  def show_stats(card_count, card_remaining)
    percent = (card_count * 100.0) / card_remaining
    @label.text = "#{'Draw chance : '._}#{percent.round(2)}%"
  end
end