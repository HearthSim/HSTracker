class InterfacePreferencesLayout < PreferencesLayout

  def options
    {
        :lock_windows => {
            :type => NSButton,
            :title => 'Lock Windows'._,
            :init => -> (elem) {
              elem.buttonType = NSSwitchButton
              elem.state = (Configuration.lock_windows ? NSOnState : NSOffState)
            },
            :changed => -> (elem) {
              Configuration.lock_windows = (elem.state == NSOnState)
              NSNotificationCenter.defaultCenter.post('lock_windows')
            }
        },
        :window_transparency => {
            :label => 'Windows Transparency'._,
            :type => NSSlider,
            :init => -> (elem) {
              elem.minValue = 0.0
              elem.maxValue = 1.0
              elem.floatValue = Configuration.window_transparency
            },
            :changed => -> (elem) {
              Configuration.window_transparency = elem.floatValue
              NSNotificationCenter.defaultCenter.post('window_transparency')
            }
        }
    }
  end

end