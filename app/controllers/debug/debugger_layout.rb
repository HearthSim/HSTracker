class DebuggerLayout < TrackerLayout

  def layout
    frame([50, 50, 300, 400])
    title 'Debugger'

    style_mask NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask | NSClosableWindowMask

    add NSScrollView, :text_view_superview do
      autoresizing_mask NSViewWidthSizable | NSViewHeightSizable

      text_view = add NSTextView, :text_view do

        set_vertically_resizable true
        set_horizontally_resizable false
        autoresizing_mask NSViewWidthSizable
        textContainer.setWidthTracksTextView true
        rich_text false

        parent_bounds = v.superview.bounds
        frame parent_bounds
      end

      document_view text_view

      constraints do
        width.equals(:superview)
        top.is 0
        height.equals(:superview).minus(50)
      end
    end
    add NSButton, :debug do
      constraints do
        top.equals(:text_view_superview, :bottom).plus(5)
        center_x.equals(:superview)
      end
    end
  end

end