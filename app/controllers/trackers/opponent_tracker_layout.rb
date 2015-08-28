class OpponentTrackerLayout < TrackerLayout

  # get the window frame
  def window_frame
    frame = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      frame = SizeHelper.opponent_tracker_frame
    end

    if frame.nil?
      _frame = NSUserDefaults.standardUserDefaults.objectForKey window_name
      if _frame
        frame = NSRectFromString(_frame)
      end
    end

    if frame.nil?
      h = CGRectGetMidY(NSScreen.mainScreen.frame)
      width = case Configuration.card_layout
                when :small
                  KSmallFrameWidth
                when :medium
                  KMediumFrameWidth
                else
                  KFrameWidth
              end

      frame = [[0, h - TrackerLayout::KFrameHeight / 2],
               [width, TrackerLayout::KFrameHeight]]
    end

    frame
  end

  def window_name
    'HSTrackerOpponent'
  end

  def window_title
    :opponent._
  end

end
