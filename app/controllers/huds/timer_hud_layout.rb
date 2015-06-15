class TimerHudLayout < MK::WindowLayout

  def layout
    wframe = [[400, 120], [200, 80]]
    frame  = NSUserDefaults.standardUserDefaults.objectForKey 'HSTimer'
    if frame
      wframe = NSRectFromString(frame)
    end

    frame(wframe)
    identifier 'HSTimer'
    title 'Timer'._

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
      font_size 28
      constraints do
        width.equals(:superview).minus(10)
        height.equals(:superview).minus(10)
      end
    end
  end

end