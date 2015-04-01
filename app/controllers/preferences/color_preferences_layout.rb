class ColorPreferencesLayout < PreferencesLayout

  def frame_size
    [[0, 0], [300, 300]]
  end

  KOnCardLayoutChoices = {
      :big    => 'Big'._,
      :medium => 'Medium'._,
      :small  => 'Small'._
  }

  KOnCardPlayedChoices = {
      :fade   => 'Fade'._,
      :remove => 'Remove'._
  }

  def options
    {
        :card_played => {
            :label => 'Card played'._,
            :type  => NSPopUpButton,
            :init => -> (elem) {
              current_choice     = Configuration.card_played

              KOnCardPlayedChoices.each do |value, label|
                item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_choice == value
                  elem.selectItem item
                end
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KOnCardPlayedChoices.each do |value, label|
                if choosen == label
                  Configuration.card_played = value
                end
              end
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
        :card_layout         => {
            :label   => 'Card size'._,
            :type    => NSPopUpButton,
            :init    => -> (elem) {
              current_choice = Configuration.card_layout

              KOnCardLayoutChoices.each do |value, label|
                item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
                elem.menu.addItem item

                if current_choice == value
                  elem.selectItem item
                end
              end
            },
            :changed => -> (elem) {
              choosen = elem.selectedItem.title

              KOnCardLayoutChoices.each do |value, label|
                if choosen == label
                  Configuration.card_layout = value
                end
              end
            }
        }
    }
  end

end