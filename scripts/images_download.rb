#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'open-uri'
require 'mini_magick'

langs          = %w(deDE enUS esES frFR ptBR ruRU zhCN)
valid_card_set = %w(KARA) #%w(CORE EXPERT1 NAXX GVG BRM TGT LOE PROMO REWARD HERO_SKINS OG KARA)

resource_dir = "#{File.dirname(__FILE__)}/../HSTracker/Resources/Cards"

MiniMagick.configure do |config|
  config.whiny = false
  config.cli = :imagemagick
end

def download(url, image_path)
  File.open(image_path, "wb") do |saved_file|
    open(url, "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

# download the coin
langs.each do |lang|
  lang_dir = "/Users/benjamin/Desktop/Cards/#{lang.downcase}"
  unless File.exist?(lang_dir)
    FileUtils.mkdir_p lang_dir
  end
end

File.open("#{resource_dir}/cardsDB.enUS.json", 'r') do |file|
  cards = JSON.parse file.read

  download_cards = ['GAME_005']

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
        url = "http://wow.zamimg.com/images/hearthstone/cards/#{lang.downcase}/medium/#{card['id']}.png?13921"

        download(url, image_path)
      end
    end
  end
end
