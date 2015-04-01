class CountTextCellView < NSTableCellView
  attr_accessor :text

  def text=(value)
    @text = value
    setNeedsDisplay true
  end

  def drawRect(rect)
    super.tap do
      case layout
        when :small
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
        when :medium
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
        else
          ratio = 1.0
      end

      name = text.attrd
                 .font('Belwe Bd BT'.nsfont((14.0 / ratio).round))
                 .stroke_width(-1.5)
                 .stroke_color(:black.nscolor)
                 .foreground_color(:white.nscolor)
      x                  = 10.0 / ratio
      y                  = -3.0 / ratio
      width              = 174.0 / ratio
      height             = 30.0 / ratio
      name.drawInRect [[x, y], [width, height]]
    end
  end
end