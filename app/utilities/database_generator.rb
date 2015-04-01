class DatabaseGenerator
  include CDQ

  # usefull if we need to force reloading of database
  DATABASE_VERSION = 3

  Log = Motion::Log

  def self.init_database(&block)
    database = DatabaseGenerator.new
    database.load(&block)
  end

  def database_need_generation
    return true if RUBYMOTION_ENV == 'test'

    if Card.count.zero?
      return true
    end

    database_version = NSUserDefaults.standardUserDefaults.objectForKey 'database_version'
    return true if database_version.nil? or database_version.to_i < DATABASE_VERSION

    false
  end

  # save all cards if Card model is empty
  def load(&block)
    unless database_need_generation
      block.call if block
      return
    end

    Card.destroy_all
    Mechanic.destroy_all

    # do all the creation in background
    cdq.background do
      if RUBYMOTION_ENV == 'test'
        langs = %w(deDE enUS frFR)
      else
        langs = %w(deDE enGB enUS esES esMX frFR itIT koKR plPL ptBR ptPT ruRU zhCN zhTW)
      end
      valid_card_set = [
          'Basic',
          'Classic',
          'Reward',
          'Promotion',
          'Curse of Naxxramas',
          'Goblins vs Gnomes',
          'Blackrock Mountain'
      ]
      invalid_cards  = %w(BRMA)

      langs.each do |lang|
        Log.verbose "#{lang} -> #{"cards/cardsDB.#{lang}.json".resource_path}"
        data  = NSData.read_from "cards/cardsDB.#{lang}.json".resource_path
        cards = JSON.parse data

        valid_card_set.each do |card_set|
          cards[card_set].each do |card|

            invalid_card = false
            # check for invalid card
            invalid_cards.each do |invalid|
              if card['id'] =~ /^#{invalid}/
                invalid_card = true
                next
              end
            end
            next if invalid_card

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
        cdq.save(always_wait: true)
      end

      Dispatch::Queue.main.async do
        NSUserDefaults.standardUserDefaults.setObject(DATABASE_VERSION, forKey: 'database_version')
        cdq.save

        block.call if block
      end
    end
  end

end