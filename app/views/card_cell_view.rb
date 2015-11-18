class CardCellView < NSTableCellView

  attr_accessor :card, :side, :delegate, :card_size

  def init
    super.tap do
      self.wantsLayer = true

      @flash_alpha = 0.0

      # the layer for the card art
      @card_layer = CALayer.layer
      self.layer << @card_layer

      # the layer for the frame
      @frame_layer = CALayer.layer
      self.layer << @frame_layer

      # the layer for the gem art
      @gem_layer = CALayer.layer
      self.layer << @gem_layer

      @cost_layer = CATextLayer.layer
      @cost_layer.contentsScale = NSScreen.mainScreen.backingScaleFactor
      self.layer << @cost_layer

      @text_layer = CATextLayer.layer
      @text_layer.contentsScale = NSScreen.mainScreen.backingScaleFactor
      self.layer << @text_layer

      @frame_count_box = CALayer.layer
      self.layer << @frame_count_box

      @extra_info = CALayer.layer
      self.layer << @extra_info

      # the layer for flashing the card on draw
      @flash_layer = CALayer.layer
      self.layer << @flash_layer

      @mask_layer = CALayer.layer
      @mask_layer.contents = ImageCache.frame_image_mask
    end
  end

  def flash
    @flash_layer.backgroundColor = Configuration.flash_color.cgcolor
    fade = CABasicAnimation.animationWithKeyPath('opacity')
    fade.fromValue = 0.7
    fade.toValue = 0.0
    fade.duration = 0.5

    fade.removedOnCompletion = false
    fade.fillMode = KCAFillModeBoth

    @flash_layer.addAnimation(fade, forKey: 'alpha')
  end

  def wantsUpdateLayer
    true
  end

  # drawing
  def updateLayer
    if side == :player
      alpha = (card.count <= 0)
      unless Configuration.in_hand_as_played
        alpha = alpha && card.hand_count <= 0
      end

      alpha = (alpha) ? 0.4 : 1.0
    else
      alpha = (card.count <= 0) ? 0.4 : 1.0
    end

    layout = Configuration.card_layout
    if card_size
      layout = card_size
    end
    ratio = case layout
               when :small
                 TrackerLayout::KRowHeight / TrackerLayout::KSmallRowHeight
               when :medium
                 TrackerLayout::KRowHeight / TrackerLayout::KMediumRowHeight
               else
                 1.0
             end

    # draw the card art
    @card_layer.contents = ImageCache.small_card_image(card)
    x = 104.0 / ratio
    y = 1.0 / ratio
    width = 110.0 / ratio
    height = 34.0 / ratio
    @card_layer.frame = [[x, y], [width, height]]
    @card_layer.opacity = alpha

    if card.rarity && Configuration.rarity_colors
      rarity = card.rarity
      @gem_layer.contents = ImageCache.gem_image(rarity)
    else
      rarity = nil
      @gem_layer.contents = nil
    end

    x = 3.0 / ratio
    y = 4.0 / ratio
    width = 28.0 / ratio
    height = 28.0 / ratio
    frame_rect = [[x, y], [width, height]]
    @gem_layer.frame = frame_rect
    @gem_layer.opacity = alpha

    # draw the frame
    if card.is_stolen
      @frame_layer.contents = ImageCache.frame_deck_image
    else
      @frame_layer.contents = ImageCache.frame_image(rarity)
    end

    x = 1.0 / ratio
    y = 0.0 / ratio
    width = 218.0 / ratio
    height = 35.0 / ratio
    frame_rect = [[x, y], [width, height]]
    @frame_layer.frame = frame_rect
    @frame_layer.opacity = alpha

    stroke_color = :black.nscolor(alpha)
    foreground = :white.nscolor(alpha)
    if card.hand_count > 0 && side == :player
      foreground = Configuration.flash_color.nscolor(alpha)
    end

    # print the card name
    if Configuration.is_cyrillic_or_asian
      font = 'NanumGothic'.nsfont((18.0 / ratio).round)
    else
      font = 'Belwe Bd BT'.nsfont((15.0 / ratio).round)
    end

    name = card.name.attrd
             .font(font)
             .foreground_color(foreground)

    unless Configuration.is_cyrillic_or_asian
      name = name.stroke_width(-2)
               .stroke_color(stroke_color)
    end
    x = 38.0 / ratio
    y = -3.0 / ratio
    width = 174.0 / ratio
    height = 30.0 / ratio
    @text_layer.frame = [[x, y], [width, height]]
    @text_layer.string = name

    card_cost = card.cost
    # print the card cost
    cost = "<center>#{card_cost}</center>".attributed_html
             .foreground_color(foreground)
             .font('Belwe Bd BT'.nsfont((22.0 / ratio).round))
             .stroke_width(-1.5)
             .stroke_color(stroke_color)

    card_cost > 9 ? x = (7.0 / ratio) : x = 13.0 / ratio
    y = -4.0 / ratio
    width = 34.0 / ratio
    height = 37.0 / ratio

    return if width.nil? || height.nil?
    @cost_layer.frame = [[x, y], [width, height]]
    @cost_layer.string = cost

    # by default, we only show 2 or more
    min_count = Configuration.show_one_card ? 1 : 2

    if card.count >= min_count || card.rarity == :legendary._
      # add the background of the card count
      if card.is_stolen
        @frame_count_box.contents = ImageCache.frame_countbox_deck
      else
        @frame_count_box.contents = ImageCache.frame_countbox
      end
      x = 189.0 / ratio
      y = 5.0 / ratio
      width = 25.0 / ratio
      height = 24.0 / ratio
      @frame_count_box.frame = [[x, y], [width, height]]

      if card.count.between?(min_count, 9) && card.rarity != :legendary._
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
      @extra_info.contents = nil
      @frame_count_box.contents = nil
    end
    @frame_count_box.opacity = alpha
    @extra_info.opacity = alpha

    @flash_layer.frame = self.bounds
    @mask_layer.frame = frame_rect
    @flash_layer.mask = @mask_layer
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
    self.delegate.hover(self) if self.delegate
  end

  def mouseExited(_)
    self.delegate.out(self) if self.delegate
  end

end
