class TooltipLayout < MK::WindowLayout

  def layout
    frame [[0, 0], [250, 300]]
    content_max_size [250, CGRectGetHeight(NSScreen.mainScreen.frame)]
    background_color :white.nscolor(0.9)

    opaque false

    style_mask NSBorderlessWindowMask
    level NSScreenSaverWindowLevel

    add NSTextView, :card_label do
      editable false
      draws_background false
      horizontally_resizable false

      constraints do
        height.equals(:superview).minus(20)
        top.equals(:superview).plus(10)
        left.equals(:superview).plus(10)
        right.equals(:superview).minus(10)
      end
    end
  end
end