class DatabaseGenerator
  include CDQ

  Log = Motion::Log

  def self.init_database
    DatabaseGenerator.new
  end

  # save all cards if Card model is empty
  def initialize
    return unless Card.count.zero?

    langs          = %w(deDE enGB enUS esES esMX frFR itIT koKR plPL ptBR ptPT ruRU zhCN zhTW)
    valid_card_set = [
        'Basic',
        'Classic',
        'Reward',
        'Promotion',
        'Curse of Naxxramas',
        'Goblins vs Gnomes'
    ]

    langs.each do |lang|
      Log.verbose lang, "cards/cardsDB.#{lang}.json".resource_path
      data  = NSData.read_from "cards/cardsDB.#{lang}.json".resource_path
      cards = JSON.parse data

      valid_card_set.each do |card_set|
        cards[card_set].each do |card|

          cost = card['cost']
          # "fake" the coin... in the game files, Coin cost is empty
          # so we set it to 0
          if  card['id'] == 'GAME_005'
            cost = 0
          end

          c = Card.create(
              :lang         => lang,
              :name         => card['name'],
              :card_id      => card['id'],
              :card_type    => card['type'],
              :text         => card['text'],
              :player_class => card['playerClass'],
              :rarity       => card['rarity'],
              :faction      => card['faction'],
              :flavor       => card['flavor'],
              :how_to_get   => card['howToGet'],
              :artist       => card['artist'],
              :cost         => cost,
              :collectible  => card['collectible']
          )

          card['mechanics'].each do |mechanic|
            m = Mechanic.where(:value => mechanic).first
            if m.nil?
              m = Mechanic.create :value => mechanic
            end
            c.mechanics << m
          end unless card['mechanics'].nil?
        end
      end
    end

    cdq.save
  end
end