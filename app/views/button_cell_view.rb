class ButtonCellView < NSTableCellView
  attr_accessor :delegate

  def drawRect(rect)
    super.tap do
      layout = Configuration.card_layout
      case layout
        when :small
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
        when :medium
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
        else
          ratio = 1.0
      end

      width = 141.0 / ratio
      height = 35.0 / ratio
      x = CGRectGetMidX(rect) - (width / 2)
      y = CGRectGetMidY(rect) - (height / 2)
      image = ImageCache.button
      image.drawInRect([[x, y], [width, height]], fromRect: NSZeroRect, operation: NSCompositeSourceOver, fraction: 1.0)

      font_size = (16.0 / ratio).round
      style = NSMutableParagraphStyle.new
      style.alignment = NSCenterTextAlignment

      name = :save._.attrd.paragraph_style(style)
               .font('Belwe Bd BT'.nsfont(font_size))
               .foreground_color(:black.nscolor)
      name.drawInRect [[x, y - 2], [width, height]]
    end
  end
end
