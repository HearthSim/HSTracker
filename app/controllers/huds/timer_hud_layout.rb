class TimerHudLayout < MK::WindowLayout

  def layout
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      hearthstone_window = OSXHelper.hearthstone_frame
      screen_height = hearthstone_window.size.height - hearthstone_window.origin.y
      mid_y = screen_height / 2

      screen_width = hearthstone_window.size.width + hearthstone_window.origin.x

      wframe = [[screen_width - 450, mid_y],
                [200, 80]]
    else
      wframe = [[400, 120], [200, 80]]
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
