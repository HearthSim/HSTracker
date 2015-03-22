class OpponentTrackerLayout < TrackerLayout

  # get the window frame
  def window_frame
    h = CGRectGetMidY(NSScreen.mainScreen.frame)

    [[0, h - TrackerLayout::KFrameHeight / 2],
     [TrackerLayout::KFrameWidth, TrackerLayout::KFrameHeight]]
  end

  def window_name
    'HSTrackerOpponent'
  end

end