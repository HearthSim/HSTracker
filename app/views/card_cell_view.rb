class CardCellView < NSTableCellView

  attr_accessor :card, :side, :delegate

  # get the card image path
  def image_path
    image = self.card.english_name.downcase.gsub(/[ ']/, '-').gsub(/[:.!]/, '')
    png_path_with_name("small/#{image}")
  end

  # shortcut method
  def png_path_with_name(file_name)
    "#{'images/'.resource_path}/#{file_name}.png"
  end

  def drawRect(rect)
    super.tap do
      frame_width = CGRectGetWidth(rect)

      alpha = 1.0
      if side == :player
        alpha = (card.count <= 0 and card.hand_count <= 0) ? 0.4 : 1.0
      end

      # draw the card image
      image       = NSImage.alloc.initWithContentsOfFile(image_path)
      image_width = frame_width == 220 ? 110 : 96
      image.drawInRect([[104, 1], [image_width, 34]],
                       fromRect:  NSZeroRect,
                       operation: NSCompositeSourceOver,
                       fraction:  alpha)

      # draw the frame
      frame_name = frame_width == 220 ? 'frame' : 'frame_small'
      frame      = NSImage.alloc.initWithContentsOfFile(png_path_with_name(frame_name))
      frame.drawInRect([[1, 0], [218, 35]],
                       fromRect:  NSZeroRect,
                       operation: NSCompositeSourceOver,
                       fraction:  alpha)

      stroke_color = :black.nscolor(alpha)
      foreground   = :white.nscolor(alpha)
      if card.hand_count > 0 and side == :player
        foreground = [113.0, 210.0, 207.0].nscolor(alpha)
      end

      # print the card cost
      cost = "<center>#{card.cost}</center>".attributed_html
                 .font('Belwe Bd BT'.nsfont(22))
                 .stroke_width(-1.5)
                 .stroke_color(stroke_color)
                 .foreground_color(foreground)
      cost.drawInRect [[2, 1], [34, 37]]

      # print the card name
      name       = card.name.attrd
                       .font('Belwe Bd BT'.nsfont(15))
                       .stroke_width(-1.5)
                       .stroke_color(stroke_color)
                       .foreground_color(foreground)
      name_width = (frame_width == 220) ? 184 : 178
      name.drawInRect [[37, 2], [name_width, 30]]

      if card.count >= 2 or card.rarity == 'Legendary'
        # not the most elegant thing in the world...
        frame_count_x   = (frame_width == 220) ? 189 : 179
        extra_info_x    = (frame_width == 220) ? 194 : 185

        # add the background of the card count
        frame_count_box = NSImage.alloc.initWithContentsOfFile(png_path_with_name('frame_countbox'))
        frame_count_box.drawInRect([[frame_count_x, 5], [25, 24]],
                                   fromRect:  NSZeroRect,
                                   operation: NSCompositeSourceOver,
                                   fraction:  alpha)

        if card.count >= 2 && card.count <= 9
          # the card count
          extra_info = NSImage.alloc.initWithContentsOfFile(png_path_with_name("frame_#{card.count}"))
          extra_info.drawInRect([[extra_info_x, 8], [18, 21]],
                                fromRect:  NSZeroRect,
                                operation: NSCompositeSourceOver,
                                fraction:  alpha)
        else
          # card is legendary (or count > 10)
          extra_info = NSImage.alloc.initWithContentsOfFile(png_path_with_name('frame_legendary'))
          extra_info.drawInRect([[extra_info_x, 8], [18, 21]],
                                fromRect:  NSZeroRect,
                                operation: NSCompositeSourceOver,
                                fraction:  alpha)
        end
      end
    end
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
    return if card.count.zero?

    self.delegate.hover(self) if self.delegate
  end

  def mouseExited(_)
    return if card.count.zero?
    self.delegate.out(self) if self.delegate
  end
end