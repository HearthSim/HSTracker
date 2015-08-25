class TimerHudLayout < MK::WindowLayout

  def layout
    wframe = nil
    size = [100, 80]
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      hearthstone_window = OSXHelper.hearthstone_frame
      unless hearthstone_window.nil?
        point = [hearthstone_window.size.width - 290 - size[0], hearthstone_window.size.height / 2 + 15]
        point = OSXHelper.point_relative_to_hearthstone(point)
        unless point.nil?
          wframe = [point, size]
        end
      end
    end

    if wframe.nil?
      wframe = [[400, 120], size]
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
