class InterfacePreferencesLayout < PreferencesLayout

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