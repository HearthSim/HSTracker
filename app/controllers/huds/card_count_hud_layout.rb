class CardCountHudLayout < MK::WindowLayout
  attr_accessor :player

  def window_name
    self.player == :player ? 'HSPlayerCardCount' : 'HSOpponentCardCount'
  end

  def layout
    wframe = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      wframe = self.player == :player ? SizeHelper.player_card_count_frame : SizeHelper.opponent_card_count_frame
    end

    if wframe.nil?
      wframe = self.player == :player ? [[200, 200], [120, 90]] : [[200, 400], [120, 90]]
      frame = NSUserDefaults.standardUserDefaults.objectForKey window_name
      if frame
        wframe = NSRectFromString(frame)
      end
    end

    frame(wframe)
    identifier window_name
    title self.player == :player ? :player_card_count._ : :opponent_card_count._

    # transparent all the things \o|
    opaque false
    has_shadow false
    background_color :black.nscolor(Configuration.window_transparency)

    locked = Configuration.windows_locked

    if locked
      mask = NSBorderlessWindowMask
    else
      mask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
    end
    ignores_mouse_events locked
    style_mask mask
    if Hearthstone.instance.is_active?
      level NSScreenSaverWindowLevel
    end

    add TextHud, :label do
      constraints do
        width.equals(:superview).minus(10)
        height.equals(:superview).minus(10)
      end
    end
  end
end
