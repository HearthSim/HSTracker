class DeckManagerLayout < MK::WindowLayout

  def layout
    frame_width  = CGRectGetWidth(NSScreen.mainScreen.frame) - 100
    frame_height = CGRectGetHeight(NSScreen.mainScreen.frame) - 100

    frame [[0, 0], [frame_width, frame_height]], 'HSTrackerDeckManager'
    title 'Deck Manager'._

    toolbar = NSToolbar.new
    toolbar toolbar

    item = NSToolbarItem.alloc.initWithItemIdentifier 'import'
    item.label = 'Import Deck'._
    toolbar.insertItemWithItemIdentifier item, atIndex: 0

    add NSView, :left do
      constraints do
        height.equals(:superview)
        top_left.equals x: 0, y: 0
        width.equals(:superview).minus(130)
      end
    end

    add NSView, :right do
      constraints do
        width.equals(250)
        top_right.equals x: 0, y: 0
        height.equals(:superview)
      end
    end
  end

  def right_style

    add NSButton, :new_deck do
      title 'New Deck'._
      bezelStyle NSTexturedRoundedBezelStyle

      constraints do
        bottom.equals(:superview, :bottom).minus(10)
        right.equals(:superview).minus(10)
        left.equals(:superview).minus(10)
      end
    end

    add NSScrollView, :table_scroll_view do
      autoresizing_mask NSViewWidthSizable | NSViewHeightSizable

      document_view add NSTableView, :table_view
      has_vertical_scroller true

      constraints do
        top.equals(0)
        bottom.equals(:new_deck, :top).minus(10)
        right.equals(:superview)
        left.equals(:superview)
      end
    end
  end

  def table_view_style
    row_height 37
    intercellSpacing [0, 0]

    background_color :black.nscolor(0.1)
    parent_bounds = v.superview.bounds
    frame parent_bounds

    add_column 'cards_or_decks' do
      width parent_bounds.size.width
      resizingMask NSTableColumnAutoresizingMask
    end
  end

end