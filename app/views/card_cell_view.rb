class CardCellView < NSTableCellView
  attr_accessor :card, :side

  # path of the bundle images path
  def absolute_path
    'images/'.resource_path
  end

  # get the card image path
  def image_path
    image = self.card.english_name.downcase.gsub(/[ ']/, '-').gsub(/[:.!]/, '')
    "#{absolute_path}/#{image}.png"
  end

  # shortcut method
  def png_path_with_name(file_name)
    "#{absolute_path}/#{file_name}.png"
  end

  def drawRect(rect)
    super.tap do
      alpha = 1.0
      if side == :player
        alpha = (card.count <= 0 and card.hand_count <= 0) ? 0.4 : 1.0
      end

      # draw the card image
      image = NSImage.alloc.initWithContentsOfFile(image_path)
      image.drawInRect([[104, 1], [110, 34]],
                       fromRect:  NSZeroRect,
                       operation: NSCompositeSourceOver,
                       fraction:  alpha)

      # draw the frame
      frame = NSImage.alloc.initWithContentsOfFile(png_path_with_name('frame'))
      frame.drawInRect([[1, 0], [218, 35]],
                       fromRect:  NSZeroRect,
                       operation: NSCompositeSourceOver,
                       fraction:  alpha)

      stroke_color = :black.nscolor(alpha)
      foreground = :white.nscolor(alpha)
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
      name            = card.name.attrd
                            .font('Belwe Bd BT'.nsfont(15))
                            .stroke_width(-1.5)
                            .stroke_color(stroke_color)
                            .foreground_color(foreground)
      name.drawInRect [[37, 2], [184, 30]]

      if card.count >= 2 or card.rarity == 'Legendary'
        # add the background of the card count
        frameCountBox            = NSImage.alloc.initWithContentsOfFile(png_path_with_name('frame_countbox'))
        frameCountBox.drawInRect([[189, 5], [25, 24]],
                                 fromRect:  NSZeroRect,
                                 operation: NSCompositeSourceOver,
                                 fraction:  alpha)

        if card.count >= 2 && card.count <= 9
          # the card count
          extraInfo            = NSImage.alloc.initWithContentsOfFile(png_path_with_name("frame_#{card.count}"))
          extraInfo.drawInRect([[194, 8], [18, 21]],
                               fromRect:  NSZeroRect,
                               operation: NSCompositeSourceOver,
                               fraction:  alpha)
        else
          # card is legendary (or count > 10)
          extraInfo            = NSImage.alloc.initWithContentsOfFile(png_path_with_name('frame_legendary'))
          extraInfo.drawInRect([[194, 8], [18, 21]],
                               fromRect:  NSZeroRect,
                               operation: NSCompositeSourceOver,
                               fraction:  alpha)
        end
      end
    end
  end
end