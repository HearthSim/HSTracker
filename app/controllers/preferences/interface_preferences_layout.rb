class InterfacePreferencesLayout < PreferencesLayout

  KHandCountOptions = {
      :hidden  => 'Hidden'._,
      :tracker => 'On trackers'._,
      :window  => 'Detached windows'._
  }

  KSkinOptions = {
      :default     => 'Default'._,
      :hearthstats => 'HearthStats'
  }

  def frame_size
    [[0, 0], [400, 350]]
  end

  def options
    NSColorPanel.sharedColorPanel.continuous = false

    {
        :windows_locked      => 'Lock Windows'._,
        :window_transparency => {
            :label   => 'Windows Transparency'._,
            :type    => NSSlider,
            :init    => -> (elem) {
              elem.minValue   = 0.0
              elem.maxValue   = 1.0
              elem.floatValue = Configuration.window_transparency
            },
            :changed => -> (elem) {
              Configuration.window_transparency = elem.floatValue
            }
        },
        :show_get_cards      => 'Show stolen cards'._,
        :show_card_on_hover  => 'Show card on hover'._,
        :fixed_window_names  => 'Fixed window names'._,
        :hand_count_window   => {
            :label   => 'Card count / Draw chance'._,
            :type    => NSPopUpButton,
            :init    => -> (elem) {
              current_choice = Configuration.hand_count_window

              KHandCountOptions.each do |value, label|
                item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_choice == value
                  elem.selectItem item
                end
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KHandCountOptions.each do |value, label|
                if choosen == label
                  Configuration.hand_count_window = value
                end
              end
            }
        },
        :in_hand_as_played   => 'Consider in-hand as played'._,
        :skin                => {
            :label   => 'Skin'._,
            :type    => NSPopUpButton,
            :init    => -> (elem) {
              current_choice = Configuration.skin

              KSkinOptions.each do |value, label|
                item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_choice == value
                  elem.selectItem item
                end
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KSkinOptions.each do |value, label|
                if choosen == label
                  Configuration.skin = value
                end
              end
            }
        },
        :show_timer => 'Show timers'._,
        :show_opponent_tracker => 'Show opponent tracker'._
    }
  end

end