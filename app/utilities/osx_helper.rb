class OSXHelper

  def self.is_10_10?
    self.is_version? 10, 10
  end

  def self.is_10_9?
    self.is_version? 10, 9
  end

  def self.is_10_8?
    self.is_version? 10, 8
  end

  def self.gt_10_10?
    self.gt_version? 10, 10
  end

  def self.gt_10_9?
    self.gt_version? 10, 9
  end

  def self.gt_10_8?
    self.gt_version? 10, 8
  end

  def self.is_version?(major, minor)
    _major, _minor = get_version

    _major == major && _minor == minor
  end

  def self.gt_version?(major, minor)
    _major, _minor = get_version

    _major >= major && _minor >= minor
  end

  # Get the frame of the Hearthstone window.
  # The size is reduced with the title bar height
  def self.hearthstone_frame
    # TODO need a way to check moving Hearthstone window and reset @hearthstone_frame
    return @hearthstone_frame if @hearthstone_frame

    windows = CGWindowListCopyWindowInfo(KCGWindowListOptionOnScreenOnly | KCGWindowListExcludeDesktopElements, KCGNullWindowID)
    hearthstone = windows.find { |w| w['kCGWindowName'] == 'Hearthstone' }
    return nil? unless hearthstone

    bounds = Pointer.new(CGRect.type, 1)
    CGRectMakeWithDictionaryRepresentation(hearthstone['kCGWindowBounds'], bounds)

    # remove the titlebar from the height
    frame = bounds[0]
    title_height = NSWindow.frameRectForContentRect([[0, 0], [400, 400]], styleMask: NSTitledWindowMask)
    title_bar_height = title_height.size.height - 400
    frame.size.height -= title_bar_height
    # add the titlebar to y
    frame.origin.y += title_bar_height

    # OSX will return correct height for all screens, but with those screens
    #
    # +----------------+ +----------+
    # |                | |          |
    # |                | |          |
    # |                | |          |
    # |                | +----------+ <- this y will not be 0 but
    # |                |                 "mainScreen height" - or + "this screen height"
    # +----------------+                 based on mainScreen

    screen_rect = NSScreen.mainScreen.frame
    frame.origin.y = screen_rect.size.height - frame.origin.y - frame.size.height

    @hearthstone_frame = frame
    frame
  end

  # Get a point relative to Hearthstone window
  # [0, 0] will be at the bottom-left of HS window
  def self.point_relative_to_hearthstone(point)
    frame = hearthstone_frame
    return nil if frame.nil?

    point_x = point.is_a?(Array) ? point[0] : point.x
    point_y = point.is_a?(Array) ? point[1] : point.y

    x = frame.origin.x + point_x
    y = frame.origin.y + point_y

=begin
    mp hs_x: frame.origin.x,
       hs_y: frame.origin.y,
       point_x: point_x,
       point_y: point_y,
       x: x,
       y: y
=end

    [x, y]
  end

  # Get a size relative to Hearthstone window
  # All size are taken from a resolution of 1404*840 (my MBA resolution)
  # and translated to your resolution
  def self.size_relative_to_hearthstone(size)
    frame = hearthstone_frame
    return size if frame.nil?

    size_width = size.is_a?(Array) ? size[0] : size.width
    size_height = size.is_a?(Array) ? size[1] : size.height

    hs_width = frame.size.width
    hs_height = frame.size.height

    ratio_width = 1404.0 / hs_width
    ratio_height = 840.0 / hs_height

=begin
    mp hs_width: hs_width,
       hs_height: hs_height,
       ratio_width: ratio_width,
       ratio_height: ratio_height,
       size_width: size_width,
       size_height: size_height,
       new_width: size_width / ratio_width,
       new_height: size_height / ratio_height
=end

    [size_width / ratio_width, size_height / ratio_height]
  end

  private
  def self.get_version
    match = /Version (\d+)\.(\d+)/.match(NSProcessInfo.processInfo.operatingSystemVersionString)
    return 0, 0 if match.nil? || match.length != 3

    _major = match[1].to_i
    _minor = match[2].to_i

    return _major, _minor
  end

end
