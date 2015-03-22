class PlayerTrackerLayout < TrackerLayout

  # get the window frame
  def window_frame
    h = CGRectGetMidY(NSScreen.mainScreen.frame)
    w = CGRectGetMaxX(NSScreen.mainScreen.frame)

    [[w - TrackerLayout::KFrameWidth - 20, h - TrackerLayout::KFrameHeight / 2],
     [TrackerLayout::KFrameWidth, TrackerLayout::KFrameHeight]]
  end

  # get the window name
  # allow to extends
  def window_name
    'HSTrackerPlayer'
  end
end