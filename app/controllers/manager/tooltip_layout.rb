class TooltipLayout < MK::Layout

  def layout
    frame [[0, 0], [250, 200]]

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
