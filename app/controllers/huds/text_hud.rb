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

      text.attrd
          .bold(font_size)
          .stroke_width(-2.0)
          .stroke_color(:black.nscolor)
          .foreground_color(:white.nscolor)
          .drawInRect(self.bounds)

      text.attrd
          .font(NSFont.systemFontOfSize(font_size))
          .stroke_width(1.0)
          .stroke_color(:black.nscolor)
          .foreground_color(:white.nscolor)
          .drawInRect(self.bounds)
    end
  end
end