class PlayerTrackerLayout < MK::WindowLayout

  # get the x position of our window, it allow us to extends this
  # class and only change the x
  def origin_x(frame_width)
    w = CGRectGetMaxX(NSScreen.mainScreen.frame)

    w - frame_width - 20
  end

  def layout
    frame_width  = 220
    frame_height = 700

    h = CGRectGetMidY(NSScreen.mainScreen.frame)

    frame [[origin_x(frame_width), h - frame_height / 2], [frame_width, frame_height]], 'HSTracker'
    title 'HSTracker'

    content_min_size [frame_width, 200]
    content_max_size [frame_width, CGRectGetHeight(NSScreen.mainScreen.frame)]

    # transparent all the things \o|
    opaque false
    has_shadow false
    background_color :clear.nscolor

    setFrameOrigin [origin_x(frame_width), h - frame_height / 2]

    style_mask NSTitledWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask|NSBorderlessWindowMask
    level NSScreenSaverWindowLevel

    add NSScrollView, :table_scroll_view do
      drawsBackground false
      document_view add NSTableView, :table_view
    end
  end

  def table_scroll_view_style
    background_color :clear.nscolor
    frame v.superview.bounds
  end

  def table_view_style
    row_height 37
    intercellSpacing [0, 0]

    background_color :black.nscolor(0.1)

    parent_bounds = v.superview.bounds
    frame parent_bounds

    add_column 'cards' do
      width parent_bounds.size.width
      resizingMask NSTableColumnAutoresizingMask
    end
  end
end