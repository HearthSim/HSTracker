class DeckCellView < NSTableCellView
  attr_accessor :deck

  # path of the bundle images path
  def absolute_path
    'images/'.resource_path
  end

  def drawRect(rect)
    super.tap do
      # draw the class image
      image = NSImage.alloc.initWithContentsOfFile("#{absolute_path}/frames/card_bottom.png")
      image.drawInRect(rect)

      # draw the class image
      image = NSImage.alloc.initWithContentsOfFile("#{absolute_path}/heroes/#{deck.player_class.downcase}_small.png")
      image.drawInRect([[2, 2], [32, 32]])

      stroke_color = :black.nscolor
      foreground   = :white.nscolor

      # print the deck name
      name         = deck.name.attrd
                         .font('Belwe Bd BT'.nsfont(16))
                         .stroke_width(-1.5)
                         .stroke_color(stroke_color)
                         .foreground_color(foreground)
      name.drawInRect [[38, 4], [184, 30]]
    end
  end
end