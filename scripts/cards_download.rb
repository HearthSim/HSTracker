#!/usr/bin/env ruby
require 'open-uri'

url = 'https://api.hearthstonejson.com/v1/latest/'
langs = %w(deDE enUS esES esMX frFR itIT jaJP koKR plPL ptBR ruRU thTH zhCN zhTW)

def download(url, path)
  File.open(path, "wb") do |saved_file|
    open(url, "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

langs.each do |lang|
	puts "\nDownloading cards.#{lang}.json"
	download("https://api.hearthstonejson.com/v1/latest/#{lang}/cards.json", "./HSTracker/Resources/Cards/cardsDB.#{lang}.json")
end
