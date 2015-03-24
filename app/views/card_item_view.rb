class CardItemView < JNWCollectionViewCell

  attr_accessor :card, :delegate

  def card=(card)
    @card = card

    path = 'images/cards'.resource_path

    # match languages
    lang = card.lang
    if lang == 'enGB'
      lang = 'enUS'
    elsif lang == 'esMX'
      lang = 'esES'
    elsif lang == 'ptPT'
      lang = 'ptBR'
    end

    image_path = "#{path}/#{lang}/#{card.card_id}.jpg"
    unless File.exists? image_path
      image_path = "#{path}/enUS/#{card.card_id}.jpg"
    end

    image                = NSImage.alloc.initWithContentsOfFile(image_path)
    self.backgroundImage = image
  end

  # check mouse hover
  def ensureTrackingArea
    if @tracking_area.nil?
      @tracking_area = NSTrackingArea.alloc.initWithRect(NSZeroRect,
                                                         options: NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited,
                                                         owner: self,
                                                         userInfo: nil)
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
    NSCursor.pointingHandCursor.set
    self.delegate.hover(self)
  end

  def mouseExited(_)
    NSCursor.arrowCursor.set
    self.delegate.out(self)
  end

end