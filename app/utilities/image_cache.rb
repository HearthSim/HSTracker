class ImageCache
  # usefull if we need to force reloading of images
  IMAGES_VERSION = 3

  class << self

    def need_download?
      images_version = NSUserDefaults.standardUserDefaults.objectForKey 'image_version'
      return true unless dir_exists?
      return true if images_version.nil? || images_version.to_i < ImageCache::IMAGES_VERSION

      return_value = false
      path = image_path(Configuration.hearthstone_locale)
      Dir.glob(File.join(path, '*.png')).each do |file|
        size = File.size(file)

        # all files are ± 80K, check if images are less than 40K to be sure
        if size < 40960
          return_value = true
          File.delete(file)
        end
      end

      return_value
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

    def frame_image(rarity=nil)
      case rarity
      when :common._ then image = "frame_rarity_common"
      when :rare._ then image = "frame_rarity_rare"
      when :epic._ then image = "frame_rarity_epic"
      when :legendary._ then image = "frame_rarity_legendary"
      else
        image = "frame"
      end

      image_named "frames/#{image}.png"
    end

    def gem_image(rarity)
      case rarity
      when :free._ then image = "gem_rarity_free"
      when :common._ then image = "gem_rarity_common"
      when :rare._ then image = "gem_rarity_rare"
      when :epic._ then image = "gem_rarity_epic"
      when :legendary._ then image = "gem_rarity_legendary"
      else
        return nil
      end

      image_named "frames/#{image}.png"
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

    def hero(clazz, options={})
      image = image_named "heroes/#{Configuration.skin}/#{clazz.downcase}.png"
      if options.has_key?(:size) && image
        image.size = options[:size]
      end
      image
    end

    def hero_frame
      image_named 'frames/card_bottom.png'
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
