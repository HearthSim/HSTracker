class DeckManagerLayout < MK::WindowLayout

  def layout
    frame_width  = CGRectGetWidth(NSScreen.mainScreen.frame) - 100
    frame_height = CGRectGetHeight(NSScreen.mainScreen.frame) - 100

    frame [[0, 0], [frame_width, frame_height]], 'HSTrackerDeckManager'
    title 'Deck Manager'._

    add NSTabView, :tab_view do
      constraints do
        height.equals(:superview).minus(20)
        top_left.equals x: 10, y: 10
        right.equals(:right, :left).minus(10)
      end
    end

    add NSView, :right do
      constraints do
        width.equals(220)
        top_right.equals x: 0, y: 0
        height.equals(:superview)
      end
    end

  end

  def tab_view_style
    classes = %w(Shaman Hunter Warlock Druid Warrior Mage Paladin Priest Rogue Neutral)
    classes.each do |clazz|
      tab = NSTabViewItem.alloc.initWithIdentifier "#{clazz}"
      tab.label = clazz._
      addTabViewItem tab
    end
  end

  def right_style
    add NSScrollView, :table_scroll_view do
      drawsBackground false
      autoresizing_mask NSViewWidthSizable | NSViewHeightSizable

      document_view add NSTableView, :table_view
      has_vertical_scroller true

      constraints do
        height.equals(:superview)
        right.equals(:superview)
        left.equals(:superview)
      end
    end
  end

  def table_view_style
    row_height 37
    intercellSpacing [0, 0]

    background_color :clear.nscolor
    parent_bounds = v.superview.bounds

    constraints do
      height.equals(:superview)
      width.equals(:superview)
    end

    add_column 'cards_or_decks' do
      width parent_bounds.size.width
      resizingMask NSTableColumnAutoresizingMask
    end
  end

end