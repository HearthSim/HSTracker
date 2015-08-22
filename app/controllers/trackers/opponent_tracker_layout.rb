class OpponentTrackerLayout < TrackerLayout

  def self.window_size
    width = case Configuration.card_layout
              when :small
                KSmallFrameWidth
              when :medium
                KMediumFrameWidth
              else
                KFrameWidth
            end
    hearthstone_window = OSXHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    screen_height = hearthstone_window.size.height - hearthstone_window.origin.y

    [[hearthstone_window.origin.x, hearthstone_window.origin.y], [width, screen_height]]
  end

  # get the window frame
  def window_frame
    frame = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      frame = OpponentTrackerLayout.window_size
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
