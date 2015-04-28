class MainMenu < MK::MenuLayout

  def layout

    add 'HSTracker' do
      add about_item 'About HSTracker'._
      add 'Download images'._, action: 'ask_download_images:', key: ''
      add separator_item
      add preferences_item 'Preferences'._
      add separator_item
      add hide_item 'Hide HSTracker'._
      add hide_others_item 'Hide Others'._
      add show_all_item 'Show All'._
      add quit_item 'Quit HSTracker'._
    end

    add 'Edit'._ do
      add 'Cut'._, action: 'cut:', key: 'x'
      add 'Copy'._, action: 'copy:', key: 'c'
      add 'Paste'._, action: 'paste:', key: 'v'
      add 'Select All'._, action: 'selectAll:', key: 'a'
    end

    add 'Decks'._ do
      add 'Deck Manager'._, action: 'open_deck_manager:', key: 'm'
      add 'Reset'._, action: 'reset:', key: 'r'
      add separator_item

      Deck.all.sort_by(:name, :case_insensitive => true).each do |deck|
        add deck.name, action: 'open_deck:'
      end
    end

    add 'Window'._ do
      setAutoenablesItems false
      label = Configuration.windows_locked ? 'Unlock Windows'._ : 'Lock Windows'._
      add label, action: 'lock_windows:', key: 'l'
      close         = add close_item('Close'._)
      close.enabled = false

      if RUBYMOTION_ENV == 'development'
        add 'Debugger', action: 'debug:', key: ''
      end
    end
  end

end