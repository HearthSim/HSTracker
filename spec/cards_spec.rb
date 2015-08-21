describe 'Cards' do

  before do
    class << self
      include CDQ
    end
    cdq.setup
  end

  it 'should just init the database' do
    # init database
    wait_max 1000 do
      Card.count.should > 0
    end
    DatabaseGenerator.init_database(nil) do
      true.should == true
      resume
    end
  end

  it 'should find a card by its english name' do
    card = Card.by_english_name 'Dr. Boom'
    card.should.not == nil
    card.card_id.should == 'GVG_110'
  end

  it 'should find a card by its french name' do
    card = Card.by_french_name 'Dr Boum'
    card.should.not == nil
    card.card_id.should == 'GVG_110'
  end

  it 'should find a card by its id' do
    card = Card.by_id 'GVG_110'
    card.should.not == nil
    card.cost.should == 7
  end

  it 'should find a card by its name and locale' do
    card = Card.by_name_and_locale 'Dr. Bumm', 'deDE'
    card.should.not == nil
    card.card_id.should == 'GVG_110'
  end
end
