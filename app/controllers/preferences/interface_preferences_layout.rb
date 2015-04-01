class InterfacePreferencesLayout < PreferencesLayout

  def frame_size
    [[0, 0], [300, 300]]
  end

  KCardCountChoices = {
      :window          => 'Windowed'._,
      :window_one_line => 'Windowed / one line'._,
      :on_trackers     => 'On trackers'._,
      :hidden          => 'Hidden'._
  }

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
        :one_line_count      => {
            :label   => 'Card count'._,
            :type    => NSPopUpButton,
            :init    => -> (elem) {
              current_choice = Configuration.one_line_count

              KCardCountChoices.each do |value, label|
                item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_choice == value
                  elem.selectItem item
                end
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KCardCountChoices.each do |value, label|
                if choosen == label
                  Configuration.one_line_count = value
                end
              end
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
    }
  end

end