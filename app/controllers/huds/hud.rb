class Hud < Tracker

  def window_locks
    super.tap do
      locked = Configuration.windows_locked
      self.window.ignoresMouseEvents = locked
    end
  end

  def window_transparency
    self.window.backgroundColor = :black.nscolor(Configuration.window_transparency)
  end
end