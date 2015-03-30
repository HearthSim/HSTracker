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
      add 'Deck Manager'._, action: 'open_deck_manager:', key: 'm'
    end

    add 'Edit'._ do
      add item('Cut'._, action: 'cut:', key: 'x')
      add item('Copy'._, action: 'copy:', key: 'c')
      add item('Paste'._, action: 'paste:', key: 'v')
      add item('Select All'._, action: 'selectAll:', key: 'a')
    end

    add 'Decks'._ do
      add item('Reset'._, action: 'reset:', key: 'r')
      add separator_item

      Deck.all.sort_by(:name, :case_insensitive => true).each do |deck|
        add item(deck.name, action: 'open_deck:')
      end
    end

    add 'Window'._ do
      label = Configuration.windows_locked ? 'Unlock Windows'._ : 'Lock Windows'._
      add item(label, action: 'lock_windows:', key: 'l')
    end
  end

end