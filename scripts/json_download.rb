#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'open_uri_redirections'

cards_dir = "#{File.dirname(__FILE__)}/../HSTracker/Resources/Cards"
langs = %w(deDE esES itIT ptBR zhTW esMX koKR ruRU enUS frFR plPL zhCN jaJP thTH)
langs.each do |lang|
  open("#{cards_dir}/cardsDB.#{lang}.json", 'wb') do |file|
    puts "Downloading #{lang}/cards.json to cardsDB.#{lang}.json"

    url = "https://api.hearthstonejson.com/v1/latest/#{lang}/cards.json"
    file << open(url, :allow_redirections => :all).read
  end
end

