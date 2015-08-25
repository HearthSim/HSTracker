class TimerHudLayout < MK::WindowLayout

  def layout
    wframe = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      wframe = SizeHelper.timer_hud_frame
    end

    if wframe.nil?
      wframe = [[400, 120], [100, 80]]
      frame = NSUserDefaults.standardUserDefaults.objectForKey 'HSTimer'
      if frame
        wframe = NSRectFromString(frame)
      end
      identifier 'HSTimer'
    end

    frame(wframe)
    title :timer._

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
