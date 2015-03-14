class Importer

  Log = Motion::Log

  def self.load(url, &block)
    Log.debug "Loading deck from #{url}"
    AFMotion::HTTP.get(url) do |result|

      if result.nil? or result.body.nil?
        block.call(nil, nil, nil) if block
        next
      end

      Log.verbose 'Loading : OK'
      doc = Wakizashi::HTML(result.body)

      if /hearthpwn\.com\/decks/i =~ url
        deck, clazz, title = self.hearthpwn_deck(doc)
      elsif /hearthpwn\.com\/deckbuilder/i =~ url
        deck, clazz, title = self.hearthpwn_deckbuilder(url, doc)
        #elsif /hearthstone\.judgehype\.com/i =~ url
        #  deck, clazz, title = self.judgehype(doc)
      elsif /hearthstone-decks\.com/i =~ url
        deck, clazz, title = self.hearthstone_decks(doc)
      else
        Log.warn "unknown url #{url}"
        block.call(nil, nil, nil) if block
        next
      end

      if deck.nil?
        block.call(nil, nil, nil) if block
      end

      deck = Sorter.sort_deck(deck)

      block.call(deck, clazz, title) if block
    end
  end

  def self.netdeck()
    pasteboard = NSPasteboard.generalPasteboard
    paste      = pasteboard.stringForType NSPasteboardTypeString
    if paste and /^netdeckimport/ =~ paste
      lines = paste.split('\n')

      deck = []
      lines.each do |line|
        if /^name:/ =~ line
          next
        end

        if /^url:/ =~ line
          next
        end

        name = line.split(':').last
        card = Card.by_english_name name
        if deck.include? card
        else
          card.count = 1
          deck << card
        end
      end
    end
  end

  private
  # import deck from http://www.hearthstone-decks.com
  # accepted urls :
  # http://www.hearthstone-decks.com/deck/voir/yu-gi-oh-rogue-5215
  def self.hearthstone_decks(doc)
    deck = []

    title       = nil
    clazz       = nil

    # search for title
    title_nodes = doc.xpath("//div[@id='content']//h3")
    unless title_nodes.nil? or title_nodes.size.zero?
      title_node = title_nodes.first
      title      = title_node.children.last.stringValue.strip
    end

    # search for clazz
    clazz_nodes = doc.xpath("//input[@id='classe_nom']")
    unless clazz_nodes.nil? or clazz_nodes.size.zero?
      clazz_node = clazz_nodes.first

      clazz = clazz_node['value']
      if clazz
        classes = {
            'Chaman'    => 'shaman',
            'Chasseur'  => 'hunter',
            'Démoniste' => 'warlock',
            'Druide'    => 'druid',
            'Guerrier'  => 'warrior',
            'Mage'      => 'mage',
            'Paladin'   => 'paladin',
            'Prêtre'    => 'priest',
            'Voleur'    => 'rogue'
        }
        clazz   = classes[clazz]
      end
    end

    # search for cards
    cards_nodes = doc.xpath("//table[contains(@class,'tabcartes')]//tbody//tr")
    cards_nodes.each do |card_node|
      children = card_node.children

      count     = children[0].stringValue.to_i
      card_name = children[1].stringValue.strip

      card = Card.by_french_name(card_name)
      if card.nil?
        Log.warn "CARD : #{card_name} is nil"
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
  def self.judgehype(doc)
    deck = []

    title       = nil
    clazz       = nil

    # search for title
    title_nodes = doc.xpath("//div[@id='contenu-titre']//h1")
    unless title_nodes.nil? or title_nodes.size.zero?
      title_node = title_nodes.first
      title      = title_node.children.last.stringValue.strip
    end

    # search for clazz
    clazz_nodes = doc.xpath("//div[@id='contenu']//img")
    unless clazz_nodes.nil? or clazz_nodes.size.zero?
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

      Log.verbose "#{card_name} x #{count[0].to_i}"
      card = Card.by_french_name(card_name)
      if card.nil?
        Log.warn "CARD : #{card_name} is nil"
        next
      end
      card.count = count[0].to_i
      deck << card
    end

    return deck, clazz, title
  end

  # fetch and parse a deck from http://www.hearthpwn.com/decks/
  def self.hearthpwn_deck(doc)
    title       = nil
    clazz       = nil

    # search for class
    clazz_nodes = doc.xpath("//span[contains(@class,'class')]")
    unless clazz_nodes.nil? or clazz_nodes.size.zero?
      clazz_node = clazz_nodes.first
      match      = /class-(\w+)/.match clazz_node.XMLString
      unless match.nil?
        clazz = match[1]
      end
    end

    # search for title
    title_nodes = doc.xpath("//h2[contains(@class,'t-deck-title')]")
    unless title_nodes.nil? or title_nodes.size.zero?
      title_node = title_nodes.first
      title      = title_node.stringValue
    end

    # search for cards
    card_nodes = doc.xpath("//td[contains(@class,'col-name')]")
    if card_nodes.nil? or card_nodes.size.zero?
      return nil, nil, nil
    end

    deck = []
    card_nodes.each do |node|
      card_name = node.elementsForName 'b'

      next if card_name.nil?

      card_name = card_name.first.stringValue

      count = /\d+/.match node.children.lastObject.stringValue

      card = Card.by_english_name(card_name)
      Log.verbose "card #{card_name} is #{card}"
      card.count = count[0].to_i
      deck << card
    end

    return deck, clazz, title
  end

  # fetch and parse a deck from http://www.hearthpwn.com/deckbuilder
  def self.hearthpwn_deckbuilder(url, doc)
    deck  = []

    # search for class
    clazz = url.partition('#').first.split('/').last

    # search for cards
    cards = url.partition('#').last.split(';').map { |x| x.split ':' }
    cards.each do |card_id_arr|
      card_id = card_id_arr[0]
      count   = card_id_arr[1]

      path = "//tr[@data-id='#{card_id}']/td[1]/b"

      node = doc.xpath(path)
      next if node.nil? or node.size.zero?
      card_name = node.first.stringValue

      card       = Card.by_english_name(card_name)
      card.count = count.to_i
      deck << card
    end

    return deck, clazz, nil
  end

end