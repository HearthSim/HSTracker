schema '0006 hearthstats' do

  entity 'DeckCard' do
    string :card_id
    integer64 :count

    belongs_to :deck, inverse: 'Deck.cards'
  end

  entity 'Deck' do
    string :name
    string :player_class
    boolean :arena, default: false
    integer64 :version, default: 0
    boolean :is_active, default: true

    integer64 :hearthstats_id, default: 0
    integer64 :hearthstats_version_id, default: 0

    has_one :deck, minCount: 0
    has_many :cards, inverse: 'DeckCard.deck', deletionRule: 'Cascade'
    has_many :statistics, inverse: 'Statistic.deck', deletionRule: 'Cascade'
  end

  entity 'Statistic' do
    string :opponent_class
    integer64 :rank
    string :game_mode
    string :opponent_name
    boolean :win
    belongs_to :deck
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

    has_many :mechanics, plural_inverse: true
  end

end
