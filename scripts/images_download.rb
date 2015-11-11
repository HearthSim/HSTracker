#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'open-uri'
require 'mini_magick'

langs          = %w(deDE enUS esES frFR ptBR ruRU zhCN)
valid_card_set = [
    'Basic',
    'Classic',
    'Reward',
    'Promotion',
    'Curse of Naxxramas',
    'Goblins vs Gnomes',
    'Blackrock Mountain',
    'The Grand Tournament',
    'League of Explorers'
]

resource_dir = "#{File.dirname(__FILE__)}/../resources/"

MiniMagick.configure do |config|
  config.debug = false
  config.whiny = false
  config.cli = :imagemagick
end

def download(url, image_path)
  puts "Downloading #{image_path} from #{url}"

  image = MiniMagick::Image.open(url)
  image.trim
  image.resize '181x250'
  image.format 'png'
  image.write image_path
end

File.open("#{resource_dir}/cards/cardsDB.enUS.json", 'r') do |file|
  cards = JSON.parse file.read

  valid_card_set.each do |card_set|
    cards[card_set].each do |card|
      next unless card['collectible']

      langs.each do |lang|

        lang_dir = "/Users/benjamin/Desktop/HSTracker/cards/#{lang}/"
        unless File.exist?(lang_dir)
          Dir.mkdir lang_dir
        end

        image_path = "#{lang_dir}#{card['id']}.png"
        unless File.exist? image_path
          url = "http://wow.zamimg.com/images/hearthstone/cards/#{lang.downcase}/medium/#{card['id']}.png"

          download(url, image_path)
        end
      end
    end
  end
end

# also download the coin
langs.each do |lang|
  path = "/Users/benjamin/Desktop/HSTracker/cards/#{lang}/GAME_005.png"
  url = "http://wow.zamimg.com/images/hearthstone/cards/#{lang.downcase}/medium/GAME_005.png"
  download(url, path)
end
