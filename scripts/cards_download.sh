#!/usr/bin/bash

BASEDIR="$(dirname "$0")"
HSJSON="https://api.hearthstonejson.com/v1"

for lang in deDE enUS esES esMX frFR itIT jaJP koKR plPL ptBR ruRU thTH zhCN zhTW; do
	echo "Downloading cards.$lang.json"
	wget "$HSJSON/latest/$lang/cards.json" -O "$BASEDIR/../HSTracker/Resources/Cards/cardsDB.$lang.json"
done
