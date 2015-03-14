class MainMenu < MK::MenuLayout

  def layout

    add 'HSTracker' do
      add about_item 'About HSTracker'._
      add separator_item
      add preferences_item 'Preferences'._
      add separator_item
      add hide_item 'Hide HSTracker'._
      add hide_others_item 'Hide Others'._
      add show_all_item 'Show All'._
      add quit_item 'Quit HSTracker'._
    end

    add 'File'._ do
      add 'Import Deck'._, action: 'import:', key: 'i'
      add 'Deck Manager'._, action: 'open_deck_manager:', key: 'm'
    end

    add 'Edit'._ do
      add item('Cut'._, action: 'cut:', keyEquivalent: 'x')
      add item('Copy'._, action: 'copy:', keyEquivalent: 'c')
      add item('Paste'._, action: 'paste:', keyEquivalent: 'v')
      add item('Select All'._, action: 'selectAll:', keyEquivalent: 'a')
    end
  end

end