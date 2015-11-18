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

  # sort a deck
  # sort by
  # 1) card cost
  # 2) class card
  # 3) card type (spell, minion, ...)
  # 4) card name
  def sort_cards!
    sort! do |a, b|
      if a.nil? || b.nil?
        a.nil? ? 1 : -1
      elsif a.cost != b.cost
        a.cost <=> b.cost
      elsif (a.player_class.nil? && !b.player_class.nil?) || (!a.player_class.nil? && b.player_class.nil?)
        a.player_class.nil? ? 1 : -1
      elsif a.card_type != b.card_type
        b.card_type <=> a.card_type
      else
        a.name <=> b.name
      end
    end
  end

end
