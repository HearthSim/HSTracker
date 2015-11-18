class MainMenu < MK::MenuLayout

  def layout

    add 'HSTracker' do
      add about_item :about_hstracker._
      add :download_images._, action: 'ask_download_images:', key: ''
      add :reset_all._, action: 'reset_all_data:', key: ''
      add :rebuild_card_database._, action: 'rebuild_cards:', key: ''
      add separator_item
      sparkle = add :check_updates._, action: 'checkForUpdates:', key: ''
      sparkle.setTarget SUUpdater.new
      add separator_item
      add preferences_item :preferences._
      add separator_item
      add hide_item :hide_hstracker._
      add hide_others_item :hide_others._
      add show_all_item :show_all._
      add quit_item :quit_hstracker._
    end

    add :edit._ do
      add :cut._, action: 'cut:', key: 'x'
      add :copy._, action: 'copy:', key: 'c'
      add :paste._, action: 'paste:', key: 'v'
      add :select_all._, action: 'selectAll:', key: 'a'
    end

    add :decks._ do
      add :deck_manager._, action: 'open_deck_manager:', key: 'm'
      add :reset._, action: 'reset:', key: 'r'
      add :clear._, action: 'clear:', key: ''
      add :save_all._, action: 'save_decks:', key: ''
      add separator_item

      decks = {}
      Deck.where(is_active: true)
        .sort_by(:player_class)
        .sort_by(:name, case_insensitive: true)
        .each do |deck|
        unless decks.has_key?(deck.player_class.downcase._)
          decks[deck.player_class.downcase._] = []
        end
        decks[deck.player_class.downcase._] << deck
      end

      Hash[decks.sort_by {|k, _| k}].each do |clazz, _decks|
        add clazz do
          _decks.each do |deck|
            add deck.name, action: 'open_deck:'
          end
        end
      end
    end

    add :window._ do
      setAutoenablesItems false
      label = Configuration.windows_locked ? :unlock_windows._ : :lock_windows._
      lock = add label, action: 'lock_windows:', key: 'l'
      lock.enabled = !Configuration.size_from_game

      close = add close_item(:close._)
      close.enabled = false

      add separator_item
      add :show_debug_files._, action: 'open_debug:', key: ''
    end
  end

end
