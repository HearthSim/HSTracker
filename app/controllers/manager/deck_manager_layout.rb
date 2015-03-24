class DeckManagerLayout < MK::WindowLayout

  def layout
    frame_width  = CGRectGetWidth(NSScreen.mainScreen.frame) - 100
    frame_height = CGRectGetHeight(NSScreen.mainScreen.frame) - 100

    frame [[0, 0], [frame_width, frame_height]], 'HSTrackerDeckManager'
    title 'Deck Manager'._

    add NSView do

      add NSSegmentedControl, :tabs do
        segment_style NSSegmentStyleCapsule

        constraints do
          height.is 23
          top.equals(:superview).plus(10)
          center_x.equals(:superview)
        end
      end

      add JNWCollectionView, :cards_view do
        constraints do
          top.equals(:tabs, :bottom).plus(10)
          bottom.equals(:superview)
          width.equals(:superview)
        end
      end

      constraints do
        height.equals(:superview)
        left.is 0
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

  def right_style
    add NSScrollView, :table_scroll_view do
      drawsBackground false
      autoresizing_mask NSViewWidthSizable | NSViewHeightSizable

      document_view add NSTableView, :table_view
      frame v.superview.bounds
    end
  end

  def table_view_style
    row_height 37
    intercellSpacing [0, 0]

    background_color :clear.nscolor
    parent_bounds = v.superview.bounds
    frame parent_bounds

    add_column 'cards_or_decks' do
      width parent_bounds.size.width
      resizingMask NSTableColumnAutoresizingMask
    end
  end

end