class TrackerLayout < MK::WindowLayout

  KFrameWidth  = 220
  KFrameHeight = 700

  # get the window frame
  def window_frame
    [[0, 0], [0, 0]]
  end

  # get the window name
  # allow to extends
  def window_name
    'HSTracker'
  end

  def window_title
    'HSTracker'
  end

  def layout
    wframe = window_frame
    frame = NSUserDefaults.standardUserDefaults.objectForKey window_name
    if frame
      wframe = NSRectFromString(frame)
    end

    frame(wframe)
    identifier window_name
    title window_title

    content_min_size [KFrameWidth, 200]
    content_max_size [KFrameWidth, CGRectGetHeight(NSScreen.mainScreen.frame)]

    # transparent all the things \o|
    opaque false
    has_shadow false
    background_color :clear.nscolor

    locked = Configuration.windows_locked

    if locked
      mask = NSBorderlessWindowMask
    else
      mask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
    end
    style_mask mask
    level NSScreenSaverWindowLevel

    add NSScrollView, :table_scroll_view do
      drawsBackground false
      document_view add NSTableView, :table_view
    end
  end

  def table_scroll_view_style
    background_color :clear.nscolor

    constraints do
      height.equals(:superview)
      width.equals(:superview)
    end
  end

  def table_view_style
    row_height 37
    intercellSpacing [0, 0]

    background_color :black.nscolor(Configuration.window_transparency)

    parent_bounds = v.superview.bounds
    frame parent_bounds
    autoresizingMask NSViewWidthSizable | NSViewHeightSizable

    add_column 'cards' do
      width parent_bounds.size.width
      resizingMask NSTableColumnAutoresizingMask
    end
  end
end