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

  def self.hearthstone_frame
    windows = CGWindowListCopyWindowInfo(KCGWindowListOptionOnScreenOnly | KCGWindowListExcludeDesktopElements, KCGNullWindowID)
    hearthstone = windows.find { |w| w['kCGWindowName'] == 'Hearthstone' }
    return nil? unless hearthstone

    bounds = Pointer.new(CGRect.type, 1)
    CGRectMakeWithDictionaryRepresentation(hearthstone['kCGWindowBounds'], bounds)

    frame = bounds[0]
    title_height = NSWindow.frameRectForContentRect([[0, 0], [400, 400]], styleMask: NSTitledWindowMask)
    frame.size.height = frame.size.height - (title_height.size.height - 400)
    frame
  end

  def self.point_relative_to_hearthstone(point)
    frame = hearthstone_frame
    return nil if frame.nil?

    point_x = point.is_a?(Array) ? point[0] : point.x
    point_y = point.is_a?(Array) ? point[1] : point.y

    x = frame.origin.x + point_x
    y = frame.origin.y + point_y - 8

    [x, y]
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
