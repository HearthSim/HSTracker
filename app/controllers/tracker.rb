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
end