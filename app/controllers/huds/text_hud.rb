class TextHud < NSView

  attr_accessor :text, :font_size

  def font_size
    @font_size ||= 14
  end

  def text=(value)
    @text = value
    setNeedsDisplay true
  end

  def flash
    if @flash_count == 4
      @flash_count = 0
      @is_flashing = false
      setNeedsDisplay true
      return
    end

    @flash_count ||= 0
    @flash_count += 1
    @is_flashing = true

    Dispatch::Queue.concurrent.after (0.24) do
      Dispatch::Queue.main.async do
        setNeedsDisplay true
        flash
      end
    end
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

      stroke = Configuration.count_color_border
      if @is_flashing and @flash_count % 2 == 0
        stroke = :red.nscolor
      end

      size = (font_size / ratio).round
      style = NSMutableParagraphStyle.new
      style.alignment = NSCenterTextAlignment
      name = text.attrd.paragraph_style(style)
               .font('Belwe Bd BT'.nsfont(size))
               .stroke_width(-1.5)
               .stroke_color(stroke)
               .foreground_color(Configuration.count_color)
      name.drawInRect self.bounds,
                      options: NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesDeviceMetrics

    end
  end
end
