class DatabaseGenerator
  include CDQ

  # usefull if we need to force reloading of database
  DATABASE_VERSION = 1

  Log = Motion::Log

  def self.init_database(&block)
    Dispatch::Queue.main.async do
      database = DatabaseGenerator.new
      database.load

      block.call if block
    end
  end

  def database_need_genaration
    if Card.count.zero?
      return true
    end

    database_version = NSUserDefaults.standardUserDefaults.objectForKey 'database_version'
    return true if database_version.nil? or database_version.to_i < DATABASE_VERSION

    false
  end

  # save all cards if Card model is empty
  def load
    return unless database_need_genaration

    Card.destroy_all
    Mechanic.destroy_all

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
      Log.verbose "#{lang} -> #{"cards/cardsDB.#{lang}.json".resource_path}"
      data  = NSData.read_from "cards/cardsDB.#{lang}.json".resource_path
      cards = JSON.parse data

      valid_card_set.each do |card_set|
        cards[card_set].each do |card|

          cost = card['cost']
          # "fake" the coin... in the game files, Coin cost is empty
          # so we set it to 0
          if card['id'] == 'GAME_005'
            cost = 0
          end

          rarity = card['rarity']
          unless rarity.nil?
            rarity = rarity._
          end

          type = card['type']
          unless type.nil?
            type = type._
          end

          c = Card.create(
              :lang         => lang,
              :name         => card['name'],
              :card_id      => card['id'],
              :card_type    => type,
              :text         => card['text'],
              :player_class => card['playerClass'],
              :rarity       => rarity,
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

    NSUserDefaults.standardUserDefaults.setObject(DATABASE_VERSION, forKey: 'database_version')
    cdq.save
  end

end