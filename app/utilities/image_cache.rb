class ImageCache
  # usefull if we need to force reloading of images
  IMAGES_VERSION = 1

  class << self

    def need_download?
      images_version = NSUserDefaults.standardUserDefaults.objectForKey 'image_version'
      !dir_exists? or images_version.nil? or images_version.to_i < ImageCache::IMAGES_VERSION
    end

    def dir_exists?
      File.exists? image_path(Configuration.hearthstone_locale)
    end

    def card_image(card)
      lang = card.lang

      image_path = "#{image_path(lang)}/#{card.card_id}.png"
      if File.exists? image_path
        return image_named image_path, false
      end

      nil
    end

    def small_card_image(card)
      image = card.english_name.downcase.gsub(/[ ']/, '-').gsub(/[:.!]/, '')
      image_named "small/#{image}.png"
    end

    def asset(asset)
      image_named "assets/#{asset}.png"
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

    def button
      image_named 'frames/button.png'
    end

    def image_path(lang)
      "be.michotte.hstracker/cards/#{lang}".app_support_path
    end

    private
    def image_named(name, bundle_path=true)
      @images ||= {}
      if @images[name]
        return @images[name]
      end

      if bundle_path
        path = "#{'images/'.resource_path}/#{name}"
      else
        path = name
      end
      image = NSImage.alloc.initWithContentsOfFile(path)
      if image
        @images[name] = image
      end
      image
    end

  end
end