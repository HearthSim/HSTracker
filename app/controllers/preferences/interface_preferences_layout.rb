class InterfacePreferencesLayout < PreferencesLayout

  KHandCountOptions = {
      :hidden  => 'Hidden'._,
      :tracker => 'On trackers'._,
      :window  => 'Detached windows'._
  }

  def frame_size
    [[0, 0], [300, 300]]
  end

  def options
    NSColorPanel.sharedColorPanel.continuous = false

    {
        :lock_windows        => {
            :type    => NSButton,
            :title   => 'Lock Windows'._,
            :init    => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state      = (Configuration.windows_locked ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.windows_locked = (elem.state == NSOnState)
            }
        },
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
        :show_get_cards      => {
            :type    => NSButton,
            :title   => 'Show stolen cards'._,
            :init    => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state      = (Configuration.show_get_cards ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.show_get_cards = (elem.state == NSOnState)
            }
        },
        :window_names        => {
            :type    => NSButton,
            :title   => 'Fixed window names'._,
            :init    => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state      = (Configuration.fixed_window_names ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.fixed_window_names = (elem.state == NSOnState)
            }
        },
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
        }
    }
  end

end