class ColorPreferencesLayout < PreferencesLayout

  KOnCardLayoutChoices = {
    big: :big._,
    medium: :medium._,
    small: :small._
  }

  KOnCardPlayedChoices = {
    fade: :fade._,
    remove: :remove._
  }

  def options
    {
      card_played: {
        label: :card_played._,
        type: NSPopUpButton,
        init: -> (elem) {
          current_choice = Configuration.card_played

          KOnCardPlayedChoices.each do |value, label|
            item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
            elem.menu.addItem item

            if current_choice == value
              elem.selectItem item
            end
          end
        },
        changed: -> (elem) {
          choosen = elem.selectedItem.title

          KOnCardPlayedChoices.each do |value, label|
            if choosen == label
              Configuration.card_played = value
            end
          end
        }
      },
      flash_color: {
        label: :flash_color._,
        type: NSColorWell,
        init: -> (elem) {
          elem.color = Configuration.flash_color
        },
        changed: -> (elem) {
          Configuration.flash_color = elem.color
        }
      },
      count_color: {
        label: :draw_count_color._,
        type: NSColorWell,
        init: -> (elem) {
          elem.color = Configuration.count_color
        },
        changed: -> (elem) {
          Configuration.count_color = elem.color
        }
      },
      count_color_border: {
        label: :draw_count_border_color._,
        type: NSColorWell,
        init: -> (elem) {
          elem.color = Configuration.count_color_border
        },
        changed: -> (elem) {
          Configuration.count_color_border = elem.color
        }
      },
      card_layout: {
        label: :card_size._,
        type: NSPopUpButton,
        init: -> (elem) {
          current_choice = Configuration.card_layout

          KOnCardLayoutChoices.each do |value, label|
            item = NSMenuItem.alloc.initWithTitle(label, action: nil, keyEquivalent: '')
            elem.menu.addItem item

            if current_choice == value
              elem.selectItem item
            end
          end
        },
        changed: -> (elem) {
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
