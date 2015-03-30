describe 'Import decks from the web' do

  before do
    class << self
      include CDQ
    end
    Motion::Log.level = :error
    cdq.setup
  end

  after do
  end

  it 'should import from hearthstone-decks.com' do
    Importer.load 'http://www.hearthstone-decks.com/deck/voir/le-ladder-fun-9017' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Druid'

      @title.should == 'Le Ladder (Fun)'

      @arena.should == false
    end
  end

  it 'should import from hearthpwn.com/decks' do
    Importer.load 'http://www.hearthpwn.com/decks/215134-s12-legend-control-warrior' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Warrior'

      @title.should == '[S12 Legend] Control warrior'

      @arena.should == false
    end
  end

  it 'should import from hearthpwn.com/deckbuilder' do
    Importer.load 'http://www.hearthpwn.com/deckbuilder/warlock#43:2;73:1;94:2;122:2;153:2;264:2;360:2;372:2;482:1;500:1;503:1;542:2;573:1;673:1;683:1;7746:1;7749:2;12182:1;12227:2;12299:1' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Warlock'

      @title.should == nil

      @arena.should == false
    end
  end

  it 'should import from hearthstats.net' do
    Importer.load 'http://hearthstats.net/decks/hstracker-test-import' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Rogue'

      @title.should == 'HSTracker test import'

      @arena.should == false
    end
  end

  it 'should import from hearthhead.com/deck' do
    Importer.load 'http://www.hearthhead.com/deck=81740/handlock-mechanization' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Warlock'

      @title.should == 'Handlock Mechanization!'

      @arena.should == false
    end
  end

  it 'should import from hearthnews.fr' do
    Importer.load 'http://www.hearthnews.fr/decks/4096' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Druid'

      @title.should == 'Combos ClassicoClassic'

      @arena.should == false
    end
  end

  it 'should import from heartharena.com' do
    Importer.load 'http://www.heartharena.com/arena-run/260979' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should.not == nil
      @deck.count_cards.should == 30

      @clazz.should == 'Warrior'

      @title.should == nil

      @arena.should == true
    end
  end

  it 'should not import from www.google.be' do

    Importer.load 'https://www.google.be/?q=hearthstone+tracker+mac' do |deck, clazz, title, arena|
      @deck = deck
      @clazz = clazz
      @title = title
      @arena = arena
      resume
    end
    wait_max 100 do
      @deck.should == nil

      @clazz.should == nil

      @title.should == nil

      @arena.should == nil
    end
  end

end