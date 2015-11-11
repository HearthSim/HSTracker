#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'

cards_dir = "#{File.dirname(__FILE__)}/../resources/cards"
langs = %w(deDE esES itIT ptBR zhTW enGB esMX koKR ruRU enUS frFR plPL zhCN jaJP)
langs.each do |lang|
  open("#{cards_dir}/cardsDB.#{lang}.json", 'wb') do |file|
    puts "Downloading AllSets.#{lang}.json to cardsDB.#{lang}.json"
    file << open("https://hearthstonejson.com/json/AllSets.#{lang}.json").read
  end
end

