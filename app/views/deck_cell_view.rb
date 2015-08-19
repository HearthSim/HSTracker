class DeckCellView < NSTableCellView
  attr_accessor :deck

  def drawRect(rect)
    if Configuration.skin == :hearthstats
      color = ClassesData::KClassesColor[deck.player_class.downcase.to_sym]
      unless color
        color = :green.nscolor
      end
      color.set
      NSRectFill rect
    end

    super.tap do
      if Configuration.skin == :default
        # draw the class image
        image = ImageCache.hero_frame
        image.drawInRect(rect, fromRect: NSZeroRect, operation: NSCompositeSourceOver, fraction: 1.0)
      end

      # draw the class image
      image = ImageCache.hero(deck.player_class)
      if image
        image.drawInRect([[2, 2], [32, 32]], fromRect: NSZeroRect, operation: NSCompositeSourceOver, fraction: 1.0)
      end

      # print the deck name
      name = deck.name.attrd

      if Configuration.skin == :hearthstats
        name.foreground_color(:black.nscolor)
          .font('Lato-Regular'.nsfont(16))
      else
        name.font('Belwe Bd BT'.nsfont(16))
          .stroke_width(-1.5)
          .stroke_color(:black.nscolor)
          .foreground_color(:white.nscolor)
      end
      name.drawInRect([[38, 4], [184, 30]], fromRect: NSZeroRect, operation: NSCompositeSourceOver, fraction: 1.0)
    end
  end
end
