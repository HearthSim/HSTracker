class Tracker < NSWindowController

  def windowWillMiniaturize(_)
    window.setLevel(NSNormalWindowLevel)
  end

  def windowDidMiniaturize(_)
    window.setLevel(NSScreenSaverWindowLevel)
  end

  def windowDidMove(_)
    save_frame
  end

  def windowDidResize(_)
    save_frame
  end

  def save_frame
    return if Configuration.windows_locked || Configuration.size_from_game || !self.window.identifier
    NSUserDefaults.standardUserDefaults.setObject(NSStringFromRect(self.window.frame),
                                                  forKey: self.window.identifier)
  end

  def window_locks
    locked = Configuration.windows_locked

    if locked
      mask = NSBorderlessWindowMask
    else
      mask = NSTitledWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
    end
    self.window.ignoresMouseEvents = locked
    self.window.acceptsMouseMovedEvents = true
    self.window.setStyleMask mask
  end

  def card_layout
    return if @table_view.nil?

    case Configuration.card_layout
      when :small
        row_height = TrackerLayout::KSmallRowHeight
        width = TrackerLayout::KSmallFrameWidth
      when :medium
        row_height = TrackerLayout::KMediumRowHeight
        width = TrackerLayout::KMediumFrameWidth
      else
        row_height = TrackerLayout::KRowHeight
        width = TrackerLayout::KFrameWidth
    end

    frame = self.window.frame
    frame.size.width = width

    self.window.setFrame(frame, display: true)
    self.window.contentMinSize = [width, 200]
    self.window.contentMaxSize = [width, CGRectGetHeight(NSScreen.mainScreen.frame)]

    @table_view.rowHeight = row_height
    @table_view.reloadData
  end

  def showWindow(sender)
    # trigger when loading the window
    super.tap do
      @events = []
      # options
      @events << NSNotificationCenter.defaultCenter.observe('windows_locked') do |_|
        window_locks if self.respond_to?(:window_locks)
      end

      @events << NSNotificationCenter.defaultCenter.observe('window_transparency') do |_|
        window_transparency if self.respond_to?(:window_transparency)
      end

      @events << NSNotificationCenter.defaultCenter.observe('card_layout') do |_|
        card_layout if self.respond_to?(:card_layout)
      end

      %w(show_one_card count_color count_color_border).each do |opt|
        @events << NSNotificationCenter.defaultCenter.observe(opt) do |_|
          @table_view.reloadData if @table_view
        end
      end

      @events << NSNotificationCenter.defaultCenter.observe('hand_count_window') do |_|
        hand_count_window_changed if self.respond_to?(:hand_count_window_changed)
      end

      @events << NSNotificationCenter.defaultCenter.observe('resize_window') do |_|
        resize_window if self.respond_to?(:resize_window)
      end
    end
  end

  def windowWillClose(_)
    @events.each do |event|
      NSNotificationCenter.defaultCenter.unobserve(event)
    end if @events
  end

  # card hover
  def hover(cell)
    return unless Configuration.show_card_on_hover
    card = cell.card

    return if card.nil?

    if @card_hover.nil?
      @card_hover = CardHover.new
    end

    @card_hover.card = card
    @card_hover.showWindow(self.window)
    @card_hover.window.setFrameTopLeftPoint(get_point(cell))
  end

  def out(_)
    return unless Configuration.show_card_on_hover

    @card_hover.close if @card_hover
  end

  def get_point(cell)
    row = @table_view.rowForView(cell)
    rect = @table_view.frameOfCellAtColumn(0, row: row)

    offset = rect.origin.y - @table_view.enclosingScrollView.documentVisibleRect.origin.y

    window_rect = self.window.frame

    if window_rect.origin.x < @card_hover.window.frame.size.width
      x = window_rect.origin.x + window_rect.size.width
    else
      x = window_rect.origin.x - @card_hover.window.frame.size.width
    end

    y = window_rect.origin.y + window_rect.size.height - offset - 30
    if y < @card_hover.window.frame.size.height
      y = @card_hover.window.frame.size.height
    end

    [x, y]
  end

end
