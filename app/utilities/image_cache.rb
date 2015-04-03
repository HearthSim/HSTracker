class ImageCache
  class << self

    def card_image(card)
      # match languages
      lang = card.lang
      if lang == 'enGB'
        lang = 'enUS'
      elsif lang == 'esMX'
        lang = 'esES'
      elsif lang == 'ptPT'
        lang = 'ptBR'
      end

      image_path = "cards/#{lang}/#{card.card_id}.jpg"
      unless File.exists? "#{'images/'.resource_path}/#{image_path}"
        image_path = "cards/enUS/#{card.card_id}.jpg"
      end

      image_named image_path
    end

    def small_card_image(card)
      image = card.english_name.downcase.gsub(/[ ']/, '-').gsub(/[:.!]/, '')
      image_named "small/#{image}.png"
    end

    def frame_image
      image_named 'frames/frame.png'
    end

    def frame_deck_image
      image_named 'frames/frame_deck.png'
    end

    def frame_image_mask
      image_named 'frames/frame_mask.png'
    end

    def frame_countbox
      image_named 'frames/frame_countbox.png'
    end

    def frame_countbox_deck
      image_named 'frames/frame_countbox_deck.png'
    end

    def frame_count(count)
      image_named "frames/frame_#{count}.png"
    end

    def frame_legendary
      image_named 'frames/frame_legendary.png'
    end

    private
    def image_named(name)
      @images ||= {}
      if @images[name]
        return @images[name]
      end

      path          = "#{'images/'.resource_path}/#{name}"
      image         = NSImage.alloc.initWithContentsOfFile(path)
      @images[name] = image

      image
    end

  end
end