class CardHoverLayout < MK::WindowLayout

  def layout
    wframe = [[400, 120], [200, 80]]
    frame  = NSUserDefaults.standardUserDefaults.objectForKey 'HSDrawProb'
    if frame
      wframe = NSRectFromString(frame)
    end

    frame(wframe)
    identifier 'HSDrawProb'
    title 'Draw Chance'._

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