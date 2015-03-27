# The Card model we use while playing
class PlayCard

  attr_accessor :count, :hand_count, :card_id, :name, :english_name, :cost,
                :health, :player_class, :rarity, :card_type, :has_changed

  def self.from_card(card)
    c              = self.new
    c.count        = card.count
    c.hand_count   = 0
    c.card_id      = card.card_id
    c.name         = card.name
    c.english_name = card.english_name
    c.cost         = card.cost
    c.health       = card.health
    c.player_class = card.player_class
    c.rarity       = card.rarity
    c.card_type    = card.card_type
    c.has_changed  = false

    c
  end

  # the number of this card we have in our deck
  def count
    @count ||= 1
  end

  # the number of this card we have in hand
  def hand_count
    @hand_count ||= 0
  end
end