describe 'Configuration' do

  before do
    Configuration.reset
  end

  it 'should accept a "hearthstone_locale" option' do
    value = Configuration.hearthstone_locale
    value.should.not.nil?

    should.not.raise(ArgumentError) { Configuration.hearthstone_locale = 'ruRU' }
    value = Configuration.hearthstone_locale
    value.should == 'ruRU'
  end

  it 'should accept a "card_played" option' do
    value = Configuration.card_played
    value.should == :fade

    should.not.raise(ArgumentError) { Configuration.card_played = :remove }
    value = Configuration.card_played
    value.should == :remove
  end

  it 'should accept a "windows_locked" option' do
    value = Configuration.windows_locked
    value.should == false

    should.not.raise(ArgumentError) { Configuration.windows_locked = true }
    value = Configuration.windows_locked
    value.should == true
  end

  it 'should accept a "window_transparency" option' do
    value = Configuration.window_transparency
    value.should == 0.1

    should.not.raise(ArgumentError) { Configuration.window_transparency = 1.0 }
    value = Configuration.window_transparency
    value.should == 1.0
  end

  it 'should accept a "flash_color" option' do
    value = Configuration.flash_color
    value.should == [55, 189, 223].nscolor

    should.not.raise(ArgumentError) { Configuration.flash_color = '#FFFFFF'.nscolor }
    value = Configuration.flash_color
    value.should == '#FFFFFF'.nscolor
  end

  it 'should accept a "count_color" option' do
    value = Configuration.count_color
    value.should == [255, 255, 255].nscolor

    should.not.raise(ArgumentError) { Configuration.count_color = '#FF00FF'.nscolor }
    value = Configuration.count_color
    value.should == '#FF00FF'.nscolor
  end

  it 'should accept a "count_color_border" option' do
    value = Configuration.count_color_border
    value.should == [0, 0, 0].nscolor

    should.not.raise(ArgumentError) { Configuration.count_color_border = '#FF00FF'.nscolor }
    value = Configuration.count_color_border
    value.should == '#FF00FF'.nscolor
  end

  it 'should accept a "fixed_window_names" option' do
    value = Configuration.fixed_window_names
    value.should == false

    should.not.raise(ArgumentError) { Configuration.fixed_window_names = true }
    value = Configuration.fixed_window_names
    value.should == true
  end

  it 'should accept a "reset_on_end" option' do
    value = Configuration.reset_on_end
    value.should == false

    should.not.raise(ArgumentError) { Configuration.reset_on_end = true }
    value = Configuration.reset_on_end
    value.should == true
  end

  it 'should accept a "card_layout" option' do
    value = Configuration.card_layout
    value.should == :big

    should.not.raise(ArgumentError) { Configuration.card_layout = :small }
    value = Configuration.card_layout
    value.should == :small
  end

  it 'should not accept a "bmichotte_is_the_best" option' do
    should.raise(ArgumentError) { Configuration.bmichotte_is_the_best = true }
    should.raise(ArgumentError) { value = Configuration.bmichotte_is_the_best }
  end

  it 'should accept a "count_color" option' do
    value = Configuration.count_color
    value.should == [255, 255, 255].nscolor

    should.not.raise(ArgumentError) { Configuration.count_color = '#FF00FF'.nscolor }
    value = Configuration.count_color
    value.should == '#FF00FF'.nscolor
  end

  it 'should accept a "count_color_border" option' do
    value = Configuration.count_color_border
    value.should == [0, 0, 0].nscolor

    should.not.raise(ArgumentError) { Configuration.count_color_border = '#FF00FF'.nscolor }
    value = Configuration.count_color_border
    value.should == '#FF00FF'.nscolor
  end

  it 'should accept a "hand_count_window" option' do
    value = Configuration.hand_count_window
    value.should == :tracker

    should.not.raise(ArgumentError) { Configuration.hand_count_window = :window }
    value = Configuration.hand_count_window
    value.should == :window
  end

  it 'should accept a "show_get_cards" option' do
    value = Configuration.show_get_cards
    value.should == false

    should.not.raise(ArgumentError) { Configuration.show_get_cards = true }
    value = Configuration.show_get_cards
    value.should == true
  end

  it 'should accept a "show_card_on_hover" option' do
    value = Configuration.show_card_on_hover
    value.should == true

    should.not.raise(ArgumentError) { Configuration.show_card_on_hover = false }
    value = Configuration.show_card_on_hover
    value.should == false
  end

  it 'should accept a "in_hand_as_played" option' do
    value = Configuration.in_hand_as_played
    value.should == false

    should.not.raise(ArgumentError) { Configuration.in_hand_as_played = true }
    value = Configuration.in_hand_as_played
    value.should == true
  end

  it 'should accept a "count_color" option' do
    value = Configuration.count_color
    value.should == [255, 255, 255].nscolor

    should.not.raise(ArgumentError) { Configuration.count_color = '#FF00FF'.nscolor }
    value = Configuration.count_color
    value.should == '#FF00FF'.nscolor
  end

  it 'should accept a "count_color_border" option' do
    value = Configuration.count_color_border
    value.should == [0, 0, 0].nscolor

    should.not.raise(ArgumentError) { Configuration.count_color_border = '#FF00FF'.nscolor }
    value = Configuration.count_color_border
    value.should == '#FF00FF'.nscolor
  end

  it 'should accept a "hand_count_window" option' do
    value = Configuration.hand_count_window
    value.should == :tracker

    should.not.raise(ArgumentError) { Configuration.hand_count_window = :window }
    value = Configuration.hand_count_window
    value.should == :window
  end

  it 'should accept a "show_get_cards" option' do
    value = Configuration.show_get_cards
    value.should == false

    should.not.raise(ArgumentError) { Configuration.show_get_cards = true }
    value = Configuration.show_get_cards
    value.should == true
  end

  it 'should accept a "show_card_on_hover" option' do
    value = Configuration.show_card_on_hover
    value.should == true

    should.not.raise(ArgumentError) { Configuration.show_card_on_hover = false }
    value = Configuration.show_card_on_hover
    value.should == false
  end

  it 'should accept a "in_hand_as_played" option' do
    value = Configuration.in_hand_as_played
    value.should == false

    should.not.raise(ArgumentError) { Configuration.in_hand_as_played = true }
    value = Configuration.in_hand_as_played
    value.should == true
  end

  it 'should accept a "use_hearthstats" option' do
    value = Configuration.use_hearthstats
    value.should == false

    should.not.raise(ArgumentError) { Configuration.use_hearthstats = true }
    value = Configuration.use_hearthstats
    value.should == true
  end

  it 'should accept a "hearthstats_token" option' do
    value = Configuration.hearthstats_token
    value.should == nil

    should.not.raise(ArgumentError) { Configuration.hearthstats_token = '12345' }
    value = Configuration.hearthstats_token
    value.should == '12345'
  end

  it 'should accept a "show_notifications" option' do
    value = Configuration.show_notifications
    value.should == true

    should.not.raise(ArgumentError) { Configuration.show_notifications = false }
    value = Configuration.show_notifications
    value.should == false
  end

  it 'should accept a "remember_last_deck" option' do
    value = Configuration.remember_last_deck
    value.should == true

    should.not.raise(ArgumentError) { Configuration.remember_last_deck = false }
    value = Configuration.remember_last_deck
    value.should == false
  end

  it 'should accept a "skin" option' do
    value = Configuration.skin
    value.should == :hearthstats

    should.not.raise(ArgumentError) { Configuration.skin = :default }
    value = Configuration.skin
    value.should == :default
  end

  it 'should accept a "show_timer" option' do
    value = Configuration.show_timer
    value.should == true

    should.not.raise(ArgumentError) { Configuration.show_timer = false }
    value = Configuration.show_timer
    value.should == false
  end

  it 'should accept a "show_opponent_tracker" option' do
    value = Configuration.show_opponent_tracker
    value.should == true

    should.not.raise(ArgumentError) { Configuration.show_opponent_tracker = false }
    value = Configuration.show_opponent_tracker
    value.should == false
  end

end