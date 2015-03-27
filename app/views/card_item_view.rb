class CardItemView < JNWCollectionViewCell

  attr_accessor :card, :delegate

  def card=(card)
    @card = card

    self.backgroundImage = ImageCache.card_image(card)
  end

  # check mouse hover
  def ensure_tracking_area
    if @tracking_area.nil?
      @tracking_area = NSTrackingArea.alloc.initWithRect(NSZeroRect,
                                                         options: NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited,
                                                         owner: self,
                                                         userInfo: nil)
    end
  end

  def updateTrackingAreas
    super.tap do
      ensure_tracking_area
      unless trackingAreas.include?(@tracking_area)
        addTrackingArea(@tracking_area)
      end
    end
  end

  def mouseEntered(_)
    NSCursor.pointingHandCursor.set
    self.delegate.hover(self)
  end

  def mouseExited(_)
    NSCursor.arrowCursor.set
    self.delegate.out(self)
  end

end