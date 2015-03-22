class Tracker < NSWindowController

  def windowWillMiniaturize(_)
    window.setLevel(NSNormalWindowLevel)
  end

  def windowDidMiniaturize(_)
    window.setLevel(NSScreenSaverWindowLevel)
  end

  def windowDidMove(_)
    save_frame
  end

  def windowDidResize(_)
    save_frame
  end

  def save_frame
    NSUserDefaults.standardUserDefaults.setObject(NSStringFromRect(self.window.frame),
                                                  forKey: self.window.identifier)
  end

  def window_locks
    locked = Configuration.lock_windows

    if locked
      mask = NSBorderlessWindowMask
    else
      mask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
    end
    self.window.setStyleMask mask
  end

  def showWindow(sender)
    # trigger when loading the window
    window_locks

    super.tap do
      @option_changed = NSNotificationCenter.defaultCenter.observe 'lock_windows' do |notification|
        window_locks
      end
    end
  end

  def windowWillClose(_)
    NSNotificationCenter.defaultCenter.unobserve(@option_changed)
  end
end