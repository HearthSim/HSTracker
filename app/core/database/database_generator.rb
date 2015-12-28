module App
  module Database
    class Generator
      include CDQ

      # usefull if we need to force reloading of database
      DATABASE_VERSION = 12

      def self.init_database(splash, &block)
        database = Generator.new
        database.load(splash, &block)
      end

      def database_need_generation
        return true if RUBYMOTION_ENV == 'test'

        if Card.count.zero?
          return true
        end

        database_version = Store[:database_version]
        return true if database_version.nil? || database_version.to_i < DATABASE_VERSION

        false
      end

      # save all cards if Card model is empty
      def load(splash, &block)
        unless database_need_generation
          block.call if block
          return
        end

        Card.destroy_all
        Mechanic.destroy_all

        valid_card_set = %w(CORE EXPERT1 NAXX GVG BRM TGT LOE PROMO REWARD)

        languages = ['en_US', Store[:hearthstone_locale]].uniq
        data = NSData.read_from "cards/cardsDB.#{languages.first}.json".resource_path

        Dispatch::Queue.main.async do
          splash.max(data.size * 2)
        end if splash

        # do all the creation in background
        cdq.background do

          languages.each do |lang|

            log(:database, "#{lang} -> #{"cards/cardsDB.#{lang}.json".resource_path}")
            data = NSData.read_from "cards/cardsDB.#{lang}.json".resource_path
            cards = JSON.parse data

            locale = NSLocale.alloc.initWithLocaleIdentifier lang
            locale_name == locale.displayNameForKey(NSLocaleIdentifier, value: lang).titleize

            cards.each do |card|
              card_name = card['name']

              Dispatch::Queue.main.async do
                splash.progress(:loading._(name: card_name))
              end if splash

              next unless valid_card_set.include?(card['set'])

              cost = card['cost']
              # "fake" the coin... in the game files, Coin cost is empty
              # so we set it to 0
              if card['id'] == 'GAME_005'
                cost = 0
              end

              rarity = card['rarity']
              unless rarity.nil?
                rarity = rarity.downcase._
              end

              type = card['type']
              unless type.nil?
                type = type.downcase
              end

              player_class = card['playerClass']
              unless player_class.nil?
                player_class = player_class.downcase.ucfirst
              end

              c = Card.create(
                lang: lang,
                name: card_name,
                card_id: card['id'],
                card_type: type,
                text: card['text'],
                player_class: player_class,
                rarity: rarity,
                faction: card['faction'],
                flavor: card['flavor'],
                how_to_get: card['howToEarn'],
                artist: card['artist'],
                cost: cost,
                collectible: card['collectible']
              )

              card['mechanics'].each do |mechanic|
                m = Mechanic.where(value: mechanic).first
                if m.nil?
                  m = Mechanic.create value: mechanic
                end
                c.mechanics << m
              end unless card['mechanics'].nil?
            end
            cdq.save(always_wait: true)
          end

          Dispatch::Queue.main.async do
            Store[:database_version] = DATABASE_VERSION
            cdq.save

            block.call if block
          end
        end
      end
    end
  end
end
