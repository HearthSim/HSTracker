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
    points = {
      1 => [[671.5, 20]],
      2 => [[628.5, 20], [715.5, 20]],
      3 => [[578.5, 10], [672.5, 20], [764.5, 7]],
      4 => [[567.5, -2], [637.5, 15], [706.5, 20], [776.5, 11]],
      5 => [[561.5, 5], [616.5, 17], [671.5, 22], [729.5, 16], [786.5, 3]],
      6 => [[554.5, -10], [602.5, 7], [648.5, 16], [696.5, 19], [743.5, 16], [791.5, 5]],
      7 => [[551.5, -6], [591.5, 7], [631.5, 16], [671.5, 20], [711.5, 18], [751.5, 9], [794.5, -3]],
      8 => [[545.5, -11], [581.5, -3], [616.5, 9], [652.5, 17], [686.5, 20], [723.5, 18], [759.5, 11], [797.5, 0]],
      9 => [[541.5, -10], [573.5, 0], [603.5, 10], [633.5, 19], [665.5, 20], [697.5, 20], [728.5, 13], [762.5, 3], [795.5, -12]],
      10 => [[529.5, -10], [560.5, -9], [590.5, 0], [618.5, 9], [646.5, 16], [675.5, 20], [704.5, 17], [732.5, 10], [762.5, 3], [797.5, -11]]
    }

    hearthstone_window = SizeHelper.hearthstone_frame
    return nil if hearthstone_window.nil?
    #point = [hearthstone_window.size.width / 2, 0]
    point = [0, 0]
    size = [40, 80]
    if points.has_key?(card_count) && points[card_count][position]
      point = points[card_count][position]
    end

    SizeHelper.frame_relative_to_hearthstone([point, size])
  end

  def self.debug
    Game.instance.opponent_tracker.window.backgroundColor = NSColor.blueColor
    Game.instance.opponent_tracker.window.setFrame(opponent_tracker_frame, display: true)

    Game.instance.opponent_tracker.card_huds.each_with_index do |hud, index|
      hud.text = index.to_s
      hud.window.backgroundColor = [rand(255), rand(255), rand(255), 0.4].nscolor
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
    #hearthstone = windows.find { |w| w['kCGWindowName'] =~ /Sublime/ || w['kCGWindowOwnerName'] =~ /Sublime/ }
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

module Kernel
  def hud(num)
    @x = SizeHelper.hearthstone_frame.size.width / 2
    @y = 0
    @current_hud = Game.instance.opponent_tracker.card_huds[num]
  end

  def center
    point = [SizeHelper.hearthstone_frame.size.width / 2, 0]
    size = [40, 80]
    
    frame = SizeHelper.frame_relative_to_hearthstone([point, size])
    @current_hud.window.setFrame(frame, display: true)
  end

  def reset
    @x = 0
    @y = 0
    point = [@x, @y]
    size = [40, 80]
    frame = SizeHelper.frame_relative_to_hearthstone([point, size])
    Game.instance.opponent_tracker.card_huds.each do |hud|
      hud.window.setFrame(frame, display: true)
    end
  end

  def move(w, value)
    frame = @current_hud.window.frame
    case w
    when :up
      @y -= value
    when :down
      @y += value
    when :left
      @x -= value
    when :right
      @x += value
    end
    frame = SizeHelper.frame_relative_to_hearthstone([[@x, @y], [40, 80]])
    @current_hud.window.setFrame(frame, display: true)
    [@x, @y]
  end

  def u(value=1)
    move :up, value
  end
  def d(value=1)
    move :down, value
  end
  def r(value=1)
    move :right, value
  end
  def l(value=1)
    move :left, value
  end
end
