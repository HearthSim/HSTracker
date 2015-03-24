class CardCountHud < Hud

  attr_accessor :deck_count, :hand_count, :has_coin

  Log = Motion::Log

  def initWithPlayer(player)
    init.tap do
      @layout              = CardCountHudLayout.new
      @layout.player       = player
      self.window          = @layout.window
      self.window.delegate = self

      @label = @layout.get(:label)
      reset_cards
    end
  end

  def game_end
    @label.text = nil
  end

  def reset_cards
    self.has_coin = false
    self.hand_count = 0
    self.deck_count = 30
  end

  def draw_card(_)
    self.hand_count += 1
    self.deck_count -= 1 unless self.deck_count.zero?
    print
  end

  def play_secret
    self.hand_count -= 1 unless self.hand_count.zero?
    print
  end

  def play_card(_)
    self.hand_count -= 1 unless self.hand_count.zero?
    print
  end

  def restore_card(_)
    self.deck_count += 1
    self.hand_count -= 1 unless self.hand_count.zero?
    print
  end

  def get_coin(_)
    # increment deck_count by 1 because we decrement it when the
    # coin has been drawned
    self.has_coin = true
    self.deck_count += 1
  end

  def print
    text = ("#{'Hand : '._} #{self.hand_count}\n")
    text += ("#{'Deck : '._} #{self.deck_count}")

    @label.text = text
  end
end