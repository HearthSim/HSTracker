class GeneralPreferencesLayout < MK::Layout

  def layout
    frame [[0, 0], [300, 200]]

    add NSTextField, :locale_label do
      stringValue 'Game language'._
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:superview).plus(10)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSPopUpButton, :locale do

      constraints do
        height 26

        top.equals(:locale_label, :bottom).plus(10)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end
  end

end