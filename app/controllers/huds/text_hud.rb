class TextHud < NSView

  attr_accessor :text, :font_size

  def font_size
    @font_size ||= 16
  end

  def text=(value)
    @text = value
    setNeedsDisplay true
  end

  def drawRect(rect)
    super.tap do
      return if text.nil?

      case Configuration.card_layout
        when :small
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
        when :medium
          ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
        else
          ratio = 1.0
      end

      font_size       = (14.0 / ratio).round
      style           = NSMutableParagraphStyle.new
      style.alignment = NSCenterTextAlignment
      name            = text.attrd.paragraph_style(style)
                            .font('Belwe Bd BT'.nsfont(font_size))
                            .stroke_width(-1.5)
                            .stroke_color(Configuration.count_color_border)
                            .foreground_color(Configuration.count_color)
      name.drawInRect self.bounds,
                      options: NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesDeviceMetrics

    end
  end
end