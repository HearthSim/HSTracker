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

    case Configuration.card_layout
      when :small
        ratio = TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
      when :medium
        ratio = TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
      else
        ratio = 1.0
    end

    # draw the card art
    @card_layer.contents  = ImageCache.small_card_image(card)
    x = 104.0 / ratio
    y = 1.0 / ratio
    width = 110.0 / ratio
    height = 34.0 / ratio
    @card_layer.frame     = [[x, y], [width, height]]
    @card_layer.opacity   = alpha

    # draw the frame
    @frame_layer.contents = ImageCache.frame_image

    x = 1.0 / ratio
    y = 0.0 / ratio
    width = 218.0 / ratio
    height = 35.0 / ratio
    frame_rect            = [[x, y], [width, height]]
    @frame_layer.frame    = frame_rect
    @frame_layer.opacity  = alpha

    stroke_color = :black.nscolor(alpha)
    foreground   = :white.nscolor(alpha)
    if card.hand_count > 0 and side == :player
      foreground = Configuration.flash_color.nscolor(alpha)
    end

    # print the card name
    name               = card.name.attrd
                             .font('Belwe Bd BT'.nsfont((15.0 / ratio).round))
                             .stroke_width(-2)
                             .stroke_color(stroke_color)
                             .foreground_color(foreground)
    x = 38.0 / ratio
    y = -3.0 / ratio
    width = 174.0 / ratio
    height = 30.0 / ratio
    @text_layer.frame  = [[x, y], [width, height]]
    @text_layer.string = name

    # print the card cost
    cost               = "<center>#{card.cost}</center>".attributed_html
                             .foreground_color(foreground)
    if Configuration.is_cyrillic_or_asian
      cost = cost
                 .font('GBJenLei-Medium'.nsfont((28.0 / ratio).round))
                 .foreground_color(foreground)
    else
      cost = cost
                 .font('Belwe Bd BT'.nsfont((22.0 / ratio).round))
                 .stroke_width(-1.5)
                 .stroke_color(stroke_color)
    end

    card.cost > 9 ? x = (7.0 / ratio) : x = 13.0 / ratio
    y = -4.0 / ratio
    width = 34.0 / ratio
    height = 37.0 / ratio
    @cost_layer.frame  = [[x, y], [width, height]]
    @cost_layer.string = cost

    if card.count >= 2 or card.rarity == 'Legendary'._
      # add the background of the card count
      @frame_count_box.contents = ImageCache.frame_countbox
      x = 189.0 / ratio
      y = 5.0 / ratio
      width = 25.0 / ratio
      height = 24.0 / ratio
      @frame_count_box.frame    = [[x, y], [width, height]]

      if card.count.between?(2, 9)
        # the card count
        @extra_info.contents = ImageCache.frame_count(card.count)
      else
        # card is legendary (or count > 10)
        @extra_info.contents = ImageCache.frame_legendary
      end
      x = 194.0 / ratio
      y = 8.0 / ratio
      width = 18.0 / ratio
      height = 21.0 / ratio
      @extra_info.frame = [[x, y], [width, height]]
    else
      @extra_info.contents      = nil
      @frame_count_box.contents = nil
    end
    @frame_count_box.opacity = alpha
    @extra_info.opacity      = alpha

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