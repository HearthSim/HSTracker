module OSXHelper

  def is_10_10?
    info = NSProcessInfo.processInfo.operatingSystemVersion
    info.majorVersion >= 10 and info.minorVersion >= 10
  end

  def window_frame
    windows = CGWindowListCopyWindowInfo(KCGWindowListOptionOnScreenOnly | KCGWindowListExcludeDesktopElements, KCGNullWindowID)

    hearthstone_window = nil
    windows.each do |window|
      name = window['kCGWindowName']
      bounds = Pointer.new(CGRect.type, 1)
      CGRectMakeWithDictionaryRepresentation(window['kCGWindowBounds'], bounds)

      if name == 'Hearthstone'
        hearthstone_window = bounds[0]
        puts "name: #{name}, #{NSStringFromRect(bounds[0])}"
        break
      end
    end

    hearthstone_window
  end
end