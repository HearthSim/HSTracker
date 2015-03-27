class InterfacePreferencesLayout < PreferencesLayout

  def options
    NSColorPanel.sharedColorPanel.continuous = false

    {
        :lock_windows        => {
            :type    => NSButton,
            :title   => 'Lock Windows'._,
            :init    => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state      = (Configuration.lock_windows ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.lock_windows = (elem.state == NSOnState)
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
        :flash_color         => {
            :label   => 'Flash color'._,
            :type    => NSColorWell,
            :init    => -> (elem) {
              elem.color = Configuration.flash_color
            },
            :changed => -> (elem) {
              Configuration.flash_color = elem.color
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
        }
    }
  end

end