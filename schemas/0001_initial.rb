schema '0001 initial' do

  entity 'Deck' do
    string :name

    has_many :cards, plural_inverse: true
  end

  entity 'Mechanic' do
    string :value

    has_many :cards, plural_inverse: true
  end

  entity 'Card' do
    integer64 :cost
    integer64 :health
    string :flavor
    boolean :collectible
    string :how_to_get
    string :artist
    string :card_id
    string :player_class
    string :rarity
    string :name
    string :text
    string :card_type
    string :faction
    string :lang

    has_many :decks, plural_inverse: true
    has_many :mechanics, plural_inverse: true
  end

end
