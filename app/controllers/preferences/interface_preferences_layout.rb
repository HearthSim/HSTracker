class InterfacePreferencesLayout < PreferencesLayout

  KHandCountOptions = {
    hidden: :hidden._,
    tracker: :on_trackers._,
    window: :detached_windows._
  }

  KSkinOptions = {
    default: :default._,
    hearthstats: 'HearthStats'
  }

  def frame_size
    [[0, 0], [450, 400]]
  end

  def options
    NSColorPanel.sharedColorPanel.continuous = false

    {
      windows_locked: {
        type: NSButton,
        title: :lock_windows._,
        init: -> (elem) {
          elem.buttonType = NSSwitchButton
          elem.state = (Configuration.windows_locked ? NSOnState : NSOffState)
        },
        changed: -> (elem) {
          Configuration.windows_locked = (elem.state == NSOnState)
        },
        enabled: !Configuration.size_from_game
      },
      window_transparency: {
        label: :windows_transparency._,
        type: NSSlider,
        init: -> (elem) {
          elem.minValue = 0.0
          elem.maxValue = 1.0
          elem.floatValue = Configuration.window_transparency
        },
        changed: -> (elem) {
          Configuration.window_transparency = elem.floatValue
        }
      },
      show_get_cards: :show_stolen_cards._,
      show_card_on_hover: :show_card_hover._,
      fixed_window_names: :fixed_window_names._,
      hand_count_window: {
        label: :card_count_draw_chance._,
        type: NSPopUpButton,
        init: -> (elem) {
          current_choice = Configuration.hand_count_window

          KHandCountOptions.each do |value, label|
            item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
            elem.menu.addItem item

            if current_choice == value
              elem.selectItem item
            end
          end
        },
        changed: -> (elem) {
          choosen = elem.selectedItem.title

          KHandCountOptions.each do |value, label|
            if choosen == label
              Configuration.hand_count_window = value
            end
          end
        }
      },
      in_hand_as_played: :consider_inhand_played._,
      show_one_card: :show_one_card._,
      skin: {
        label: :skin._,
        type: NSPopUpButton,
        init: -> (elem) {
          current_choice = Configuration.skin

          KSkinOptions.each do |value, label|
            item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
            elem.menu.addItem item

            if current_choice == value
              elem.selectItem item
            end
          end
        },
        changed: -> (elem) {
          choosen = elem.selectedItem.title

          KSkinOptions.each do |value, label|
            if choosen == label
              Configuration.skin = value
            end
          end
        }
      },
      show_timer: :show_timers._,
      show_opponent_tracker: :show_opponent_tracker._,
      size_from_game: {
        type: NSButton,
        title: :size_from_game._,
        init: -> (elem) {
          elem.buttonType = NSSwitchButton
          elem.state = (Configuration.size_from_game ? NSOnState : NSOffState)
        },
        changed: -> (elem) {
          Configuration.size_from_game = (elem.state == NSOnState)
          if Configuration.size_from_game && !Configuration.windows_locked
            Configuration.windows_locked = true
          end
          get(:windows_locked).enabled = !Configuration.size_from_game
        }
      },
      rarity_colors: :rarity_colors._,
      opponent_overlay: :opponent_overlay._,
    }
  end

end
