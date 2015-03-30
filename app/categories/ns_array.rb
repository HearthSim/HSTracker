class NSArray
  # count cards in a deck
  def count_cards
    self.map(&:count).inject(0, :+)
  end
end