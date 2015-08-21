class CardItemView < JNWCollectionViewCell

  attr_accessor :card, :count, :delegate, :mode

  def card=(card)
    @card = card

    image = ImageCache.card_image(card)
    self.backgroundImage = image
    if image.nil?
      self.delegate.missing_image(card)
    end
  end

  def count=(count)
    @count = count

    alpha = 1.0
    if count > 0 && (count == DeckManager::KMaxCardOccurence[mode] || card.rarity == :legendary._)
      alpha = 0.5
    end
    self.layer.opacity = alpha
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
