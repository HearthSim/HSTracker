#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'

HS_VERSION = 11461

cards_dir = "#{File.dirname(__FILE__)}/../HSTracker/Resources/Cards"
langs = %w(deDE esES itIT ptBR zhTW esMX koKR ruRU enUS frFR plPL zhCN jaJP)
langs.each do |lang|
  open("#{cards_dir}/cardsDB.#{lang}.json", 'wb') do |file|
    puts "Downloading #{lang}/cards.json to cardsDB.#{lang}.json"

    url = "https://api.hearthstonejson.com/v1/#{HS_VERSION}/#{lang}/cards.json"
    file << open(url).read
  end
end

