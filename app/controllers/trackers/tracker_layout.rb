class TrackerLayout < MK::WindowLayout

  KFrameWidth = 220.0
  KFrameHeight = 700.0
  KRowHeight = 37.0

  KMediumRowHeight = 29.0
  KMediumFrameWidth = KFrameWidth / KRowHeight * KMediumRowHeight

  KSmallRowHeight = 23.0
  KSmallFrameWidth = KFrameWidth / KRowHeight * KSmallRowHeight

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
    frame(wframe)
    title window_title

    case Configuration.card_layout
      when :small
        width = KSmallFrameWidth
      when :medium
        width = KMediumFrameWidth
      else
        width = KFrameWidth
    end

    unless OSXHelper.gt_10_10?
      width += 15
    end

    content_min_size [width, 200]
    content_max_size [width, CGRectGetHeight(NSScreen.mainScreen.frame)]

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
    ignores_mouse_events locked
    accepts_mouse_moved_events true

    style_mask mask
    if Hearthstone.instance.is_active?
      level NSScreenSaverWindowLevel
    end

    add NSScrollView, :table_scroll_view do
      document_view add NSTableView, :table_view
    end
  end

  def table_scroll_view_style
    background_color :clear.nscolor
    drawsBackground false
    unless OSXHelper.gt_10_10?
      has_vertical_scroller true
    end

    constraints do
      height.equals(:superview)
      width.equals(:superview)
    end
  end

  def table_view_style
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
