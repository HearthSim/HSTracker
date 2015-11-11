class OpponentCardHudLayout < MK::WindowLayout
  attr_accessor :position

  def window_name
    "HSOpponentCard#{position}"
  end

  def layout
    wframe = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      wframe = SizeHelper.opponent_card_hud_frame(position, 0)
    end

    if wframe.nil?
      wframe = [[200, 400], [120, 90]]
      frame = NSUserDefaults.standardUserDefaults.objectForKey window_name
      if frame
        wframe = NSRectFromString(frame)
      end
    end

    frame(wframe)
    identifier window_name

    # transparent all the things \o|
    opaque false
    has_shadow false
    background_color :clear.nscolor

    locked = Configuration.windows_locked
    style_mask NSBorderlessWindowMask

    ignores_mouse_events locked
    accepts_mouse_moved_events true

    if Hearthstone.instance.is_active?
      level NSScreenSaverWindowLevel
    end

    add TextHud, :label do
      font_size 26

      constraints do
        width.equals(:superview)
        height.equals(:superview)
      end
    end
  end
end
