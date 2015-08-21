class Deck < CDQManagedObject

  def self.upgrade_versions
    upgrade_version_done = NSUserDefaults.standardUserDefaults.objectForKey 'upgrade_version_done'
    return if upgrade_version_done

    Deck.each do |deck|
      if deck.version.nil? || deck.version.zero?
        deck.version = 1.0
        deck.is_active = true
      end
    end

    NSUserDefaults.standardUserDefaults.setObject(true, forKey: 'upgrade_version_done')
  end

  def self.by_name(name)
    Deck.where(name: name).active.first
  end

  # scope to get only the active decks
  scope :active, where(is_active: true)

  def playable_cards
    _cards = self.cards.map do |deck_card|
      card = Card.by_id deck_card.card_id
      next if card.nil?

      card.count = deck_card.count
      card
    end.compact
    _cards.sort_cards!
  end
end
