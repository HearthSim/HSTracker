class PlayerTrackerLayout < TrackerLayout

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

    screen_width = hearthstone_window.size.width + hearthstone_window.origin.x

    [[screen_width - width, hearthstone_window.origin.y], [width, screen_height]]
  end

  # get the window frame
  def window_frame
    frame = nil
    if Configuration.size_from_game && Hearthstone.instance.is_hearthstone_running?
      frame = PlayerTrackerLayout.window_size
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
