class CardHover < NSWindowController

  attr_accessor :card

  def init
    super.tap do
      @layout = CardHoverLayout.new
      self.window = @layout.window
      self.window.delegate = self

      @image_view = @layout.get(:image_view)
    end
  end

  def card=(card)
    @card = card

    @image_view.image = ImageCache.card_image(card)
  end
end
