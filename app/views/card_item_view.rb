class CardItemView < JNWCollectionViewCell

  attr_accessor :card, :delegate

  def card=(card)
    @card = card

    path = 'images/cards'.resource_path

    image                = NSImage.alloc.initWithContentsOfFile("#{path}/#{card.card_id}.png")
    self.backgroundImage = image
  end

  # check mouse hover
  def ensureTrackingArea
    if @tracking_area.nil?
      @tracking_area = NSTrackingArea.alloc.initWithRect(NSZeroRect, options: NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited, owner: self, userInfo: nil)
    end
  end

  def updateTrackingAreas
    super.tap do
      ensureTrackingArea
      unless trackingAreas.include?(@tracking_area)
        addTrackingArea(@tracking_area)
      end
    end
  end

  def mouseEntered(_)
    self.delegate.hover(self)
  end

  def mouseExited(_)
    self.delegate.out(self)
  end

end