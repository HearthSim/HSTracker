class PlayerTrackerLayout < TrackerLayout

  # get the window frame
  def window_frame
    frame = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      frame = SizeHelper.player_tracker_frame
    end

    if frame.nil?
      _frame = NSUserDefaults.standardUserDefaults.objectForKey window_name
      if _frame
        frame = NSRectFromString(_frame)
      end
    end

    if frame.nil?
      identifier window_name

      h = CGRectGetMidY(NSScreen.mainScreen.frame)
      w = CGRectGetMaxX(NSScreen.mainScreen.frame)
      width = case Configuration.card_layout
                when :small
                  KSmallFrameWidth
                when :medium
                  KMediumFrameWidth
                else
                  KFrameWidth
              end

      frame = [[w - width - 20, h - TrackerLayout::KFrameHeight / 2],
               [width, TrackerLayout::KFrameHeight]]
    end

    frame
  end

  # get the window name
  # allow to extends
  def window_name
    'HSTrackerPlayer'
  end

  def window_title
    :player._
  end

end
