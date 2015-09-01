class DeckManagerLayout < MK::WindowLayout

  def layout 
    frame_width = CGRectGetWidth(NSScreen.mainScreen.frame) - 100
    frame_height = CGRectGetHeight(NSScreen.mainScreen.frame) - 100

    frame [[0, 0], [frame_width, frame_height]], 'HSTrackerDeckManager'
    title :deck_manager._

    add NSView do

      # classes tabs
      add NSSegmentedControl, :tabs do
        segment_style NSSegmentStyleCapsule

        constraints do
          height.is 23
          top.equals(:superview).plus(10)
          center_x.equals(:superview)
        end
      end

      # cards view
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
      add NSView, :infos do

        # number of cards in deck
        add NSTextField, :card_count do
          stringValue ''
          editable false
          bezeled false
          draws_background false
          alignment NSCenterTextAlignment

          constraints do
            bottom_left.equals x: 2, y: 5
            height.equals(:superview)
            width.is 50
          end
        end

        add NSButton, :show_stats do
          image 'stats'.nsimage
          bordered false
          enabled false

          constraints do
            height.is 32
            width.is 32
            left.equals(:card_count, :right).plus(5)
          end
        end

        constraints do
          width.equals(:superview)
          top.is 0
          height.is 30
        end
      end

      # cards or decks
      add NSScrollView, :table_scroll_view do
        drawsBackground false
        autoresizing_mask NSViewWidthSizable | NSViewHeightSizable
        unless OSXHelper.gt_10_10?
          has_vertical_scroller true
        end

        table = add NSTableView, :table_view do
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

        document_view table

        constraints do
          width.equals(:superview)
          top.equals(:infos, :bottom)
          bottom.equals(:curve_view, :top)
        end
      end

      add NSView, :curve_view do
        constraints do
          width.equals(:superview)
          height.is 150
          bottom.is 0
        end
      end

      constraints do
        _width = 220
        unless OSXHelper.gt_10_10?
          _width += 15
        end
        width.equals(_width)
        top_right.equals x: 0, y: 0
        height.equals(:superview)
      end
    end

  end

end
