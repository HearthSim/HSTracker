class CardCellView < NSTableCellView

  attr_accessor :card, :side, :delegate

  def init
    super.tap do
      self.wantsLayer = true

      @flash_alpha = 0.0

      # the layer for the card art
      @card_layer  = CALayer.layer
      self.layer << @card_layer

      # the layer for the frame
      @frame_layer = CALayer.layer
      self.layer << @frame_layer

      @cost_layer = CATextLayer.layer
      self.layer << @cost_layer

      @text_layer = CATextLayer.layer
      self.layer << @text_layer

      @frame_count_box = CALayer.layer
      self.layer << @frame_count_box

      @extra_info = CALayer.layer
      self.layer << @extra_info

      # the layer for flashing the card on draw
      @flash_layer = CALayer.layer
      self.layer << @flash_layer

      @mask_layer          = CALayer.layer
      @mask_layer.contents = ImageCache.frame_image_mask
    end
  end

  def flash
    @flash_layer.backgroundColor = Configuration.flash_color.cgcolor
    fade                         = CABasicAnimation.animationWithKeyPath('opacity')
    fade.fromValue               = 0.7
    fade.toValue                 = 0.0
    fade.duration                = 0.5

    fade.removedOnCompletion = false
    fade.fillMode            = KCAFillModeBoth

    @flash_layer.addAnimation(fade, forKey: 'alpha')
  end

  def wantsUpdateLayer
    true
  end

  # drawing
  def updateLayer
    alpha = 1.0
    if side == :player
      alpha = (card.count <= 0 and card.hand_count <= 0) ? 0.4 : 1.0
    end

    # draw the card art
    @card_layer.contents  = ImageCache.small_card_image(card)
    @card_layer.frame     = [[104, 1], [110, 34]]
    @card_layer.opacity   = alpha

    # draw the frame
    @frame_layer.contents = ImageCache.frame_image
    frame_rect            = [[1, 0], [218, 35]]
    @frame_layer.frame    = frame_rect
    @frame_layer.opacity  = alpha

    stroke_color = :black.nscolor(alpha)
    foreground   = :white.nscolor(alpha)
    if card.hand_count > 0 and side == :player
      foreground = Configuration.flash_color.nscolor(alpha)
    end

    # print the card name
    name               = card.name.attrd
                             .font('Belwe Bd BT'.nsfont(15))
                             .stroke_width(-2)
                             .stroke_color(stroke_color)
                             .foreground_color(foreground)
    @text_layer.frame  = [[38, -3], [174, 30]]
    @text_layer.string = name

    # print the card cost
    cost               = "<center>#{card.cost}</center>".attributed_html
                             .foreground_color(foreground)
    if Configuration.is_cyrillic_or_asian
      cost = cost
                 .font('GBJenLei-Medium'.nsfont(28))
                 .foreground_color(foreground)
    else
      cost = cost
                 .font('Belwe Bd BT'.nsfont(22))
                 .stroke_width(-1.5)
                 .stroke_color(stroke_color)
    end

    card.cost > 9 ? x = 7 : x = 13
    @cost_layer.frame  = [[x, -4], [34, 37]]
    @cost_layer.string = cost

    if card.count >= 2 or card.rarity == 'Legendary'._
      # add the background of the card count
      @frame_count_box.contents = ImageCache.frame_countbox
      @frame_count_box.frame    = [[189, 5], [25, 24]]
      @frame_count_box.opacity  = alpha

      if card.count.between?(2, 9)
        # the card count
        @extra_info.contents = ImageCache.frame_count(card.count)
      else
        # card is legendary (or count > 10)
        @extra_info.contents = ImageCache.frame_legendary
      end
      @extra_info.frame   = [[194, 8], [18, 21]]
      @extra_info.opacity = alpha
    end

    @flash_layer.frame = self.bounds
    @mask_layer.frame  = frame_rect
    @flash_layer.mask  = @mask_layer
  end

  # check mouse hover
  def ensure_tracking_area
    if @tracking_area.nil?
      @tracking_area = NSTrackingArea.alloc.initWithRect(NSZeroRect,
                                                         options:  NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited,
                                                         owner:    self,
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
    return if card.count.zero?

    self.delegate.hover(self) if self.delegate
  end

  def mouseExited(_)
    return if card.count.zero?
    self.delegate.out(self) if self.delegate
  end

end