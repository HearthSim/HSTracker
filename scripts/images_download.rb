#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'open-uri'
require 'mini_magick'

langs          = %w(deDE enUS esES frFR ptBR ruRU zhCN)
valid_card_set = %w(CORE EXPERT1 NAXX GVG BRM TGT LOE PROMO REWARD HERO_SKINS OG)

resource_dir = "#{File.dirname(__FILE__)}/../HSTracker/Resources/Cards"

MiniMagick.configure do |config|
  config.whiny = false
  config.cli = :imagemagick
end

def download(url, image_path)
  image = MiniMagick::Image.open(url)
  image.trim
  image.resize '181x250'
  image.format 'png'
  image.write image_path
end

# download the coin
langs.each do |lang|
  lang_dir = "/Users/benjamin/Desktop/Cards/#{lang.downcase}"
  unless File.exist?(lang_dir)
    Dir.mkdir lang_dir
  end
  path = "#{lang_dir}/GAME_005.png"
  url = "http://wow.zamimg.com/images/hearthstone/cards/#{lang.downcase}/medium/GAME_005.png"
  puts "Downloading GAME_005 #{lang.downcase}"
  download(url, path)
end

File.open("#{resource_dir}/cardsDB.enUS.json", 'r') do |file|
  cards = JSON.parse file.read

  download_cards = []

  cards.each do |card|
    next unless valid_card_set.include?(card['set'])
    next unless card['collectible']

    download_cards << card
  end

  total_cards = download_cards.count
  
  langs.each do |lang|
    current = 0
    puts "\nDownloading #{lang.downcase}"
    download_cards.each do |card|
      current += 1
      print "Downloading #{card['id']}        #{current}/#{total_cards}                 \r"
      $stdout.flush 
      lang_dir = "/Users/benjamin/Desktop/Cards/#{lang.downcase}/"
      unless File.exist?(lang_dir)
        Dir.mkdir lang_dir
      end

      image_path = "#{lang_dir}#{card['id']}.png"
      unless File.exist? image_path
        url = "http://wow.zamimg.com/images/hearthstone/cards/#{lang.downcase}/medium/#{card['id']}.png?12576"

        download(url, image_path)
      end
    end
  end
end