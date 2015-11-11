class Importer

  class << self

    def supported_sites
      :import_from._(sites: "hearthpwn.com, hearthstone-decks.com,\nhearthstats.net, hearthhead.com, hearthnews.fr #{:and._} heartharena.com")
    end

    def load(url, &block)
      log(:import, "Loading deck from #{url}")
      Web.get(url) do |result|

        if result.nil?
          block.call(nil, nil, nil) if block
          next
        end

        log(:import, 'Loading : OK')
        error = Pointer.new(:id)
        doc = GDataXMLDocument.alloc.initWithHTMLString(result, error: error)
        if error[0]
          error(:import, error[0].description)
          block.call(nil, nil, nil, nil) if block
          next
        end

        arena = false
        case url
          when /hearthpwn\.com\/decks/i
            deck, clazz, title = hearthpwn_deck(doc)
          when /hearthpwn\.com\/deckbuilder/i
            deck, clazz, title = hearthpwn_deckbuilder(url, doc)
          #when /hearthstone\.judgehype\.com/i
          #  deck, clazz, title = judgehype(doc)
          when /hearthstone-decks\.com/i
            deck, clazz, title = hearthstone_decks(doc)
          when /(hearthstats\.net|hss\.io)/i
            deck, clazz, title = hearthstats(doc)
          when /hearthhead\.com\/deck=/
            deck, clazz, title = hearthhead_deck(url, doc)
          when /hearthnews\.fr/
            deck, clazz, title = hearthnews(doc)
          when /heartharena\.com/
            arena = true
            deck, clazz, title = heartharena(doc)
          else
            error(:import, "unknown url #{url}")
            block.call(nil, nil, nil, nil) if block
            next
        end

        if deck.nil? || deck.count.zero?
          block.call(nil, nil, nil, nil) if block
          next
        end

        deck.sort_cards!
        block.call(deck, clazz, title, arena) if block
      end
    end

    def import_from_file(filename, &block)
      log(:import, "Import file : #{filename}")

      locale = Configuration.hearthstone_locale
      arena = false
      clazz = nil
      cards = []
      title = File.basename(filename).gsub(/\.txt$/, '')

      File.readlines(filename).each do |line|

        # match "2xMirror Image" as well as "2 Mirror Image" or "2 GVG_002"
        if (match = /(\d)(\s|x)?([\w\s'\.:!-]+)/.match(line))
          count = match[1].to_i
          if count > 2
            arena = true
          end

          card_name = match[3].strip
          log(:import, "Searching for #{card_name}")

          # let's try by english name
          card = Card.by_english_name card_name

          # give a try to user locale
          unless card
            card = Card.by_name_and_locale card_name, locale
          end

          # finally, give a try to card_id
          unless card
            card = Card.by_id card_name
          end

          unless card
            next
          end

          if !card.player_class.nil? && clazz.nil?
            clazz = card.player_class
            log(:import, "Found class as #{clazz}")
          end

          log(:import, "Adding card #{card.name}")
          card.count = count
          cards << card
        end
      end

      if cards.count.zero?
        block.call(nil, nil, nil, nil) if block
        return
      end

      cards.sort_cards!
      block.call(cards, clazz, title, arena) if block
    end

    def netdeck(&block)
      pasteboard = NSPasteboard.generalPasteboard
      paste = pasteboard.stringForType NSPasteboardTypeString

      if paste && /^(trackerimport|netdeckimport)/ =~ paste
        lines = paste.split("\n")

        arena = false
        deck = []
        deck_name = ''
        lines.drop(1).each do |line|
          if /^name:/ =~ line
            deck_name = line.split(':').last
            log(:import, "found deck name '#{deck_name}'")
            next
          end

          if /^url:/ =~ line
            # futur work
            next
          end

          if /^arena:/ =~ line
            arena = true
            next
          end

          card = Card.by_english_name line
          next if card.nil?
          log(:import, "found card #{line}")
          if deck.include? card
            deck.each do |c|
              if c.card_id == card.card_id
                card.count += 1
              end
            end
          else
            card.count = 1
            deck << card
          end
        end

        clazz = nil
        deck.each do |card|
          unless card.player_class.nil?
            clazz = card.player_class
            next
          end
        end

        log(:import, "found deck #{deck_name} for class #{clazz}")
        deck.sort_cards!
        block.call(deck, clazz, deck_name, arena) if block
      end

      Dispatch::Queue.main.after(1) do
        netdeck(&block)
      end
    end

    private
    # import deck from http://www.hearthstone-decks.com
    # accepted urls :
    # http://www.hearthstone-decks.com/deck/voir/yu-gi-oh-rogue-5215
    def hearthstone_decks(doc)
      deck = []

      title = nil
      clazz = nil

      # search for title
      error = Pointer.new(:id)
      title_node = doc.firstNodeForXPath("//div[@id='content']//h1", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless title_node.nil?
        title = title_node.children.last.stringValue.strip
      end

      # search for clazz
      clazz_node = doc.firstNodeForXPath("//input[@id='classe_nom']", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless clazz_node.nil?
        clazz = clazz_node.attributeForName('value').stringValue
        if clazz
          classes = {
            'Chaman' => 'Shaman',
            'Chasseur' => 'Hunter',
            'Démoniste' => 'Warlock',
            'Druide' => 'Druid',
            'Guerrier' => 'Warrior',
            'Mage' => 'Mage',
            'Paladin' => 'Paladin',
            'Prêtre' => 'Priest',
            'Voleur' => 'Rogue'
          }
          clazz = classes[clazz]
        end
      end

      # search for cards
      cards_nodes = doc.nodesForXPath("//table[contains(@class,'tabcartes')]//tbody//tr", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      cards_nodes.each do |card_node|
        count = card_node.childAtIndex(0).stringValue.to_i
        card_name = card_node.childAtIndex(1).stringValue.strip

        card = Card.by_french_name(card_name)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        card.count = count
        deck << card
      end

      return deck, clazz, title
    end

    # import deck from http://hearthstone.judgehype.com
    # accepted urls :
    # http://hearthstone.judgehype.com/deck/12411/
    # FIXME : will be maybe added if judgehype correct their cards
=begin
    def judgehype(doc)
      deck = []

      title       = nil
      clazz       = nil

      # search for title
      title_nodes = doc.xpath("//div[@id='contenu-titre']//h1")
      unless title_nodes.nil? || title_nodes.size.zero?
        title_node = title_nodes.first
        title      = title_node.children.last.stringValue.strip
      end

      # search for clazz
      clazz_nodes = doc.xpath("//div[@id='contenu']//img")
      unless clazz_nodes.nil? || clazz_nodes.size.zero?
        clazz_node = clazz_nodes.first

        match = /select-(\w+)\.png/.match clazz_node.XMLString
        unless match.nil?
          classes = {
              'chaman'    => 'shaman',
              'chasseur'  => 'hunter',
              'demoniste' => 'warlock',
              'druide'    => 'druid',
              'guerrier'  => 'warrior',
              'mage'      => 'mage',
              'paladin'   => 'paladin',
              'pretre'    => 'priest',
              'voleur'    => 'rogue'
          }
          clazz   = classes[match[1]]
        end
      end

      # search for cards
      cards_nodes = doc.xpath("//table[contains(@class,'contenu')][1]//tr")
      cards_nodes.each do |card_node|
        children = card_node.children

        next unless children.size >= 3
        td_node = children[3]
        next if td_node.nil?

        td_children = td_node.children
        next unless td_children.size == 3
        count     = /\d+/.match td_children[0].stringValue
        card_name = td_children[2].stringValue

        log(:import, "#{card_name} x #{count[0].to_i}")
        card = Card.by_french_name(card_name)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        card.count = count[0].to_i
        deck << card
      end

      return deck, clazz, title
    end
=end

    # fetch and parse a deck from http://www.hearthpwn.com/decks/
    def hearthpwn_deck(doc)
      title = nil
      clazz = nil

      # search for class
      error = Pointer.new(:id)
      clazz_node = doc.firstNodeForXPath("//span[contains(@class,'class')]", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless clazz_node.nil?
        match = /class-(\w+)/.match clazz_node.XMLString
        unless match.nil?
          clazz = match[1].ucfirst
        end
      end

      # search for title
      title_node = doc.firstNodeForXPath("//h2[contains(@class,'deck-title')]", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless title_node.nil?
        title = title_node.stringValue
      end

      # search for cards
      card_nodes = doc.nodesForXPath("//td[contains(@class,'col-name')]", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      if card_nodes.nil? || card_nodes.size.zero?
        return nil, nil, nil
      end

      deck = []
      card_nodes.each do |node|
        card_name = node.elementsForName 'b'

        next if card_name.nil?

        card_name = card_name.first.stringValue.strip

        count = /\d+/.match node.children.lastObject.stringValue

        card = Card.by_english_name(card_name)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        log(:import, "card #{card_name} is #{card}")
        card.count = count[0].to_i
        deck << card
      end

      return deck, clazz, title
    end

    # fetch and parse a deck from http://www.hearthpwn.com/deckbuilder
    def hearthpwn_deckbuilder(url, doc)
      deck = []

      # search for class
      clazz = url.partition('#').first.split('/').last.ucfirst

      # search for cards
      cards = url.partition('#').last.split(';').map { |x| x.split ':' }
      cards.each do |card_id_arr|
        card_id = card_id_arr[0]
        count = card_id_arr[1]

        error = Pointer.new(:id)
        node = doc.firstNodeForXPath("//tr[@data-id='#{card_id}']/td[1]/b", error: error)
        if error[0]
          error(:import, error[0].description)
          next
        end
        next if node.nil?
        card_name = node.stringValue

        card = Card.by_english_name(card_name)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        card.count = count.to_i
        deck << card
      end

      return deck, clazz, nil
    end

    # fetch and parse a deck from http://www.hearthstats.net/decks/
    def hearthstats(doc)
      title = nil
      clazz = nil

      # search for class
      error = Pointer.new(:id)
      clazz_node = doc.firstNodeForXPath("//div[contains(@class,'win-count')]//img", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless clazz_node.nil?
        match = /\/assets\/Icons\/Classes\/(\w+)_Icon\.gif/.match clazz_node.attributeForName('src').stringValue
        if match
          clazz = match[1].downcase.ucfirst
        end
      end

      # search for title
      title_node = doc.firstNodeForXPath("//h1[contains(@class,'page-title')]", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless title_node.nil?
        small = title_node.elementsForName 'small'
        if small
          title_node.removeChild small.first
        end
        title = title_node.stringValue
      end

      # search for cards
      card_nodes = doc.nodesForXPath("//div[contains(@class,'cardWrapper')]", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      if card_nodes.nil? || card_nodes.size.zero?
        return nil, nil, nil
      end

      deck = []
      card_nodes.each do |node|
        next if node.childCount < 5

        card_name = node.firstNodeForXPath("div[@class='name']", error: error)
        if error[0]
          error(:import, error[0].description)
          next
        end
        card_name = card_name.stringValue

        count = node.firstNodeForXPath("div[@class='qty']", error: error)
        if error[0]
          error(:import, error[0].description)
          next
        end
        count = count.stringValue.to_i

        next if card_name.nil? || count.nil?

        card = Card.by_english_name(card_name)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        log(:import, "card #{card_name} is #{card}")
        card.count = count
        deck << card
      end

      return deck, clazz, title
    end

    # fetch and parse a deck from http://www.hearthhead.com/deck=
    def hearthhead_deck(url, doc)
      title = nil
      clazz = nil

      locale = case url
                 when /de\.hearthhead\.com/
                   'deDE'
                 when /es\.hearthhead\.com/
                   'esES'
                 when /fr\.hearthhead\.com/
                   'frFR'
                 when /pt\.hearthhead\.com/
                   'ptPT'
                 when /ru\.hearthhead\.com/
                   'ruRU'
                 else
                   'enUS'
               end

      # search for class
      error = Pointer.new(:id)
      clazz_node = doc.firstNodeForXPath("//div[@class='deckguide-hero']", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless clazz_node.nil?
        classes = {
          1 => 'Warrior',
          2 => 'Paladin',
          3 => 'Hunter',
          4 => 'Rogue',
          5 => 'Priest',
          # 6 => 'Death-Knight'
          7 => 'Shaman',
          8 => 'Mage',
          9 => 'Warlock',
          11 => 'Druid'
        }
        clazz = classes[clazz_node.attributeForName('data-class').stringValue.to_i]
      end

      # search for title
      title_node = doc.firstNodeForXPath("//h1[@id='deckguide-name']", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless title_node.nil?
        title = title_node.stringValue
      end

      # search for cards
      card_nodes = doc.nodesForXPath("//div[contains(@class,'deckguide-cards-type')]/ul/li", error: error)
      if card_nodes.nil? || card_nodes.size.zero?
        return nil, nil, nil
      end

      deck = []
      card_nodes.each do |node|
        card_node = node.childAtIndex 0
        card_name = card_node.stringValue
        node.removeChild card_node

        count = /\d+/.match node.stringValue
        if count.nil?
          count = 1
        else
          count = count[0].to_i
        end

        next if card_name.nil? || count.nil?

        card = Card.by_name_and_locale(card_name, locale)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        log(:import, "card #{card_name} is #{card}")
        card.count = count
        deck << card
      end

      return deck, clazz, title
    end

    # fetch and parse a deck from http://www.hearthnews.fr
    def hearthnews(doc)
      title = nil
      clazz = nil

      # search for class
      error = Pointer.new(:id)
      clazz_node = doc.firstNodeForXPath('//div[@hero_class]', error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless clazz_node.nil?
        clazz = clazz_node.attributeForName('hero_class').stringValue.downcase.ucfirst
      end

      # search for title
      title_node = doc.firstNodeForXPath("//div[@class='block_deck_content_deck_name']", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      unless title_node.nil?
        title = title_node.stringValue.strip
      end

      # search for cards
      card_nodes = doc.nodesForXPath("//a[@class='real_id']", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      if card_nodes.nil? || card_nodes.size.zero?
        return nil, nil, nil
      end

      deck = []
      card_nodes.each do |node|
        card_id = node.attributeForName('real_id').stringValue
        count = node.attributeForName('nb_card').stringValue.to_i

        next if card_id.nil? || count.nil?

        card = Card.by_id(card_id)
        if card.nil?
          log(:import, "CARD : #{card_id} is nil")
          next
        end
        log(:import, "card #{card_id} is #{card}")
        card.count = count
        deck << card
      end

      return deck, clazz, title
    end

    # fetch and parse a deck from http://www.heartharena.com
    def heartharena(doc)
      title = nil
      clazz = nil

      # search for class
      error = Pointer.new(:id)
      clazz_node = doc.firstNodeForXPath('//h1[@class="class"]', error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end

      unless clazz_node.nil?
        clazz = clazz_node.stringValue.sub('/', '').strip.downcase.ucfirst
      end

      # search for cards
      card_nodes = doc.nodesForXPath("//ul[@class='deckList']/li", error: error)
      if error[0]
        error(:import, error[0].description)
        return nil, nil, nil
      end
      if card_nodes.nil? || card_nodes.size.zero?
        return nil, nil, nil
      end

      deck = []
      card_nodes.each do |node|
        card_name = node.attributeForName('data-name').stringValue

        count = node.firstNodeForXPath("span[@class='quantity']",
                                       error: nil).stringValue.to_i

        next if card_name.nil? || count.nil?

        card = Card.by_english_name(card_name)
        if card.nil?
          log(:import, "CARD : #{card_name} is nil")
          next
        end
        log(:import, "card #{card_name} is #{card}")
        card.count = count
        deck << card
      end

      return deck, clazz, title
    end
  end
end
