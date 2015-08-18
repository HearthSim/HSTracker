class StatisticPanelLayout < MK::WindowLayout

  def layout
    root(NSPanel, :panel) do
      frame = [[0, 0], [500, 400]]

      frame frame

      add NSScrollView, :table_scroll_view do
        drawsBackground false
        autoresizing_mask NSViewWidthSizable | NSViewHeightSizable

        table = add NSTableView, :table_view do
          allowsColumnReordering false
          allowsColumnResizing false
          allowsMultipleSelection false
          allowsColumnSelection false

          table_width = frame[1][0]

          header_view = NSTableHeaderView.alloc.initWithFrame [[0, 0], [table_width, 35]]
          setHeaderView header_view

          row_height 40
          intercellSpacing [0, 0]

          frame frame

          classes = ClassesData::KClasses.reject { |cl| cl == 'Neutral' }
          column_width = table_width / classes.size

          add_column 'version' do
            resizingMask NSTableColumnNoResizing
            width column_width

            headerCell NSCell.alloc.initTextCell('')
          end

          classes.each do |clazz|
            add_column clazz do
              resizingMask NSTableColumnNoResizing
              width column_width

              cell = NSCell.alloc.initImageCell ImageCache.hero(clazz)
              headerCell cell
            end
          end
        end

        document_view table

        constraints do
          width.equals(:superview)
          top.equals(:superview)
          bottom.equals(:close, :top).minus(5)
        end
      end

      add NSButton, :close do
        size [100, 32]

        cell do
          title :close._
          bezelStyle NSRoundedBezelStyle
          alignment NSCenterTextAlignment
        end

        constraints do
          bottom_right.equals x: -5, y: -5
        end
      end

    end
  end

end
