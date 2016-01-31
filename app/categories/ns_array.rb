class NSArray

  def to_rect
    frame = self.flatten.reverse
    raise ArgumentError.new("A frame must have four parameters") if frame.length != 4
    NSMakeRect(frame.pop, frame.pop, frame.pop, frame.pop)
  end

  # count cards in a deck
  def count_cards
    self.map(&:count).inject(0, :+)
  end

end
