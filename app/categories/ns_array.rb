class NSArray
  # count cards in a deck
  def count_cards
    self.map(&:count).inject(0, :+)
  end

  def sort_cards!
    sort! do |a, b|
      if a.cost != b.cost
        a.cost <=> b.cost
      elsif a.card_type != b.card_type
        b.card_type <=> a.card_type
      else
        a.name <=> b.name
      end
    end
  end


end