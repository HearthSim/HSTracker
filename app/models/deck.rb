class Deck < CDQManagedObject

  def self.by_name(name)
    Deck.where(:name => name).first
  end

  # scope to get only the active decks
  scope :active, where(:is_active => true).or(:version).eq(nil)

  def playable_cards
    _cards = []
    self.cards.each do |deck_card|
      card = Card.by_id deck_card.card_id
      if card
        card.count = deck_card.count
        _cards << card
      end

    end
    _cards.sort_cards!
  end
end