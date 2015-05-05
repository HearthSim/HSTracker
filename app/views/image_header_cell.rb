class ImageHeaderCell < NSTableHeaderCell
  def initWithImage(image)
    init.tap do
      @image = image
    end
  end

  def drawRect(rect)
    super.tap do
      @image.drawInRect(rect)
    end
  end
end