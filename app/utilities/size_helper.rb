class SizeHelper

  def self.player_tracker_frame
    width = case Configuration.card_layout
              when :small
                TrackerLayout::KSmallFrameWidth
              when :medium
                TrackerLayout::KMediumFrameWidth
              else
                TrackerLayout::KFrameWidth
            end
    hearthstone_window = SizeHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    frame = [[hearthstone_window.size.width - width, 0], [width, hearthstone_window.size.height]]
    SizeHelper.frame_relative_to_hearthstone(frame)
  end

  def self.opponent_tracker_frame
    width = case Configuration.card_layout
              when :small
                TrackerLayout::KSmallFrameWidth
              when :medium
                TrackerLayout::KMediumFrameWidth
              else
                TrackerLayout::KFrameWidth
            end
    hearthstone_window = SizeHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    frame = [[0, 0], [width, hearthstone_window.size.height]]
    point = SizeHelper.frame_relative_to_hearthstone(frame)
  end

  def self.timer_hud_frame
    hearthstone_window = SizeHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    width = 100
    frame = [[hearthstone_window.size.width - 300 - width, hearthstone_window.size.height / 2 + 20], [width, 80]]
    SizeHelper.frame_relative_to_hearthstone(frame)
  end

  def self.player_card_count_frame
    hearthstone_window = SizeHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    width = 225
    frame = [[hearthstone_window.size.width - 435 - width, 275], [225, 60]]
    SizeHelper.frame_relative_to_hearthstone(frame)
  end

  def self.opponent_card_count_frame
    hearthstone_window = SizeHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    frame = [[415, hearthstone_window.size.height - 255], [225, 40]]
    SizeHelper.frame_relative_to_hearthstone(frame)
  end

  def self.opponent_card_hud_frame(position, card_count)
    point = case card_count
              when 1
                [684.0, 785.0]
              when 2
                case position
                  when 0
                    [638.0, 785.0]
                  when 1
                    [728.0, 785.0]
                  else
                    nil
                end
              when 3
                case position
                  when 0
                    [593.0, 800.0]
                  when 1
                    [683.0, 785.0]
                  when 2
                    [773.0, 800.0]
                  else
                    nil
                end
              when 4
                case position
                  when 0
                    [578.0, 800.0]
                  when 1
                    [648.0, 785.0]
                  when 2
                    [718.0, 785.0]
                  when 3
                    [788.0, 795.0]
                  else
                    nil
                end
              when 5
                case position
                  when 0
                    [563.0, 800.0]
                  when 1
                    [618.0, 785.0]
                  when 2
                    [678.0, 780.0]
                  when 3
                    [733.0, 785.0]
                  when 4
                    [793.0, 800.0]
                  else
                    nil
                end
              when 6
                case position
                  when 0
                    [548.0, 810.0]
                  when 1
                    [598.0, 800.0]
                  when 2
                    [648.0, 785.0]
                  when 3
                    [693.0, 780.0]
                  when 4
                    [738.0, 785.0]
                  when 5
                    [798.0, 800.0]
                  else
                    nil
                end
              when 7
                case position
                  when 0
                    [538.0, 805.0]
                  when 1
                    [588.0, 788.0]
                  when 2
                    [623.0, 780.0]
                  when 3
                    [663.0, 775.0]
                  when 4
                    [706.0, 780.0]
                  when 5
                    [748.0, 785.0]
                  when 6
                    [798.0, 800.0]
                  else
                    nil
                end
              when 8
                case position
                  when 0
                    [538.0, 810.0]
                  when 1
                    [578.0, 800.0]
                  when 2
                    [613.0, 790.0]
                  when 3
                    [648.0, 780.0]
                  when 4
                    [678.0, 775.0]
                  when 5
                    [718.0, 780.0]
                  when 6
                    [758.0, 785.0]
                  when 7
                    [798.0, 795.0]
                end
              when 9
                case position
                  when 0
                    [532.0, 810.0]
                  when 1
                    [566.0, 800.0]
                  when 2
                    [598.0, 788.0]
                  when 3
                    [628.0, 782.0]
                  when 4
                    [663.0, 778.0]
                  when 5
                    [693.0, 778.0]
                  when 6
                    [726.0, 782.0]
                  when 7
                    [758.0, 790.0]
                  when 8
                    [808.0, 805.0]
                  else
                    nil
                end
              when 10
                case position
                  when 0
                    [518.0, 810.0]
                  when 1
                    [558.0, 810.0]
                  when 2
                    [588.0, 795.0]
                  when 3
                    [618.0, 785.0]
                  when 4
                    [643.0, 780.0]
                  when 5
                    [673.0, 775.0]
                  when 6
                    [703.0, 775.0]
                  when 7
                    [733.0, 780.0]
                  when 8
                    [763.0, 790.0]
                  when 9
                    [803.0, 805.0]
                end
              else
                nil
            end

    if point.nil?
      hearthstone_window = SizeHelper.hearthstone_frame
      return nil if hearthstone_window.nil?
      point = [hearthstone_window.size.width / 2, 0]
    else
      point[1] = point[1] - 40 - 22
    end
    size = [40, 80]

    SizeHelper.frame_relative_to_hearthstone([point, size])
  end

  def self.debug
    Game.instance.opponent_tracker.window.backgroundColor = NSColor.blueColor
    Game.instance.opponent_tracker.window.setFrame(opponent_tracker_frame, display: true)

    Game.instance.opponent_tracker.card_huds.each_with_index do |hud, index|
      hud.text = index.to_s
      hud.window.backgroundColor = [rand(255), rand(255), rand(255)].nscolor
      hud.showWindow(nil)
      hud.resize_window_with_cards(10)
    end

    Game.instance.timer_hud.window.setFrame(timer_hud_frame, display: true)
    Game.instance.timer_hud.window.backgroundColor = NSColor.yellowColor

    Game.instance.player_tracker.window.setFrame(player_tracker_frame, display: true)
    Game.instance.player_tracker.window.backgroundColor = NSColor.redColor
  end

  # Get the title bar height
  # I could fix it at 22, but IDK if it's change on retina ie
  def self.title_bar_height
    @title_bar_height ||= begin
      title_height = NSWindow.frameRectForContentRect([[0, 0], [400, 400]], styleMask: NSTitledWindowMask)
      title_height.size.height - 400
    end
  end

  # Get the frame of the Hearthstone window.
  # The size is reduced with the title bar height
  def self.hearthstone_frame
    # TODO need a way to check moving Hearthstone window and reset @hearthstone_frame
    return @hearthstone_frame if @hearthstone_frame

    windows = CGWindowListCopyWindowInfo(KCGWindowListOptionOnScreenOnly | KCGWindowListExcludeDesktopElements, KCGNullWindowID)
    hearthstone = windows.find { |w| w['kCGWindowName'] == 'Hearthstone' }
    hearthstone = windows.find { |w| w['kCGWindowName'] =~ /Sublime/ || w['kCGWindowOwnerName'] =~ /Sublime/ }
    return nil? unless hearthstone

    bounds = Pointer.new(CGRect.type, 1)
    CGRectMakeWithDictionaryRepresentation(hearthstone['kCGWindowBounds'], bounds)

    frame = bounds[0]

    # remove the titlebar from the height
    frame.size.height -= title_bar_height
    # add the titlebar to y
    frame.origin.y += title_bar_height

    @hearthstone_frame = frame
    log hs_frame: frame
    frame
  end

  # Get a frame relative to Hearthstone window
  def self.frame_relative_to_hearthstone(frame)
    hs_frame = hearthstone_frame
    return nil if hs_frame.nil?

    if frame.is_a?(Array)
      frame = frame.to_rect
    end
    point_x = frame.origin.x
    point_y = frame.origin.y
    width = frame.size.width
    height = frame.size.height

    screen_rect = NSScreen.mainScreen.frame

    x = hs_frame.origin.x + point_x
    y = screen_rect.size.height - hs_frame.origin.y - height - point_y

    log screen_rect: screen_rect,
       hs_frame: [[hs_frame.origin.x, hs_frame.origin.y], [hs_frame.size.width, hs_frame.size.height]].to_rect,
       frame: [[point_x, point_y], [width, height]].to_rect,
       new_frame: [[x, y], [width, height]].to_rect

    [[x, y], [width, height]]
  end
end
