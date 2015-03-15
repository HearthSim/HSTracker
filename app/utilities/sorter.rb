class Sorter

  # sort a deck
  # sort by
  # 1) card cost
  # 2) card type (spell, minion, ...)
  # 3) card name
  def self.sort_cards(deck)
    deck = deck.sort do |a, b|
      if a.cost != b.cost
        a.cost <=> b.cost
      elsif a.card_type != b.card_type
        b.card_type <=> a.card_type
      else
        a.name <=> b.name
      end
    end

    deck
  end
end