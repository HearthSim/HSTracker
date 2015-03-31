#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'open-uri'
require 'mini_magick'

langs          = %w(deDE enUS esES frFR ptBR ruRU)
valid_card_set = [
    'Basic',
    'Classic',
    'Reward',
    'Promotion',
    'Curse of Naxxramas',
    'Goblins vs Gnomes'
]

resource_dir = '../resources/'

MiniMagick.configure do |config|
  config.debug = false
  config.whiny = false
  config.cli = :imagemagick
end

File.open("#{resource_dir}/cards/cardsDB.enUS.json", 'r') do |file|
  cards = JSON.parse file.read

  valid_card_set.each do |card_set|
    cards[card_set].each do |card|
      next unless card['collectible']

      langs.each do |lang|

        lang_dir = "#{resource_dir}images/cards/#{lang}/"
        unless File.exist?(lang_dir)
          Dir.mkdir lang_dir
        end

        image_path = "#{lang_dir}#{card['id']}.jpg"
        unless File.exist? image_path
          url = "http://wow.zamimg.com/images/hearthstone/cards/#{lang.downcase}/medium/#{card['id']}.png"

          puts "Downloading #{image_path} from #{url}"

          image = MiniMagick::Image.open(url)
          image.trim
          image.resize '181x250'
          image.background 'white'
          image.alpha 'remove'
          image.format 'jpg'
          image.write image_path
        end
      end
    end
  end
end

