class Deck < CDQManagedObject
  def self.by_name(name)
    Deck.where(:name => name).first
  end

  def playable_cards
    _cards = []
    self.cards.each do |deck_card|
      card = Card.by_id deck_card.card_id
      if card
        card.count = deck_card.count
        _cards << card
      end

    end
    Sorter.sort_cards(_cards)
  end
end