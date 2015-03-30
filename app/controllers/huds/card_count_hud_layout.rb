class CardCountHudLayout < MK::WindowLayout

  attr_accessor :player

  def window_name
    self.player == :player ? 'HSPlayerCardCount' : 'HSOpponentCardCount'
  end

  def layout
    wframe = self.player == :player ? [[200, 200], [120, 90]] : [[200, 400], [120, 90]]
    frame  = NSUserDefaults.standardUserDefaults.objectForKey window_name
    if frame
      wframe = NSRectFromString(frame)
    end

    frame(wframe)
    identifier window_name
    title self.player == :player ? 'Player Card Count'._ : 'Opponent Card Count'._

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
    style_mask mask
    level NSScreenSaverWindowLevel

    add TextHud, :label do
      constraints do
        width.equals(:superview).minus(10)
        height.equals(:superview).minus(10)
      end
    end
  end
end