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
end