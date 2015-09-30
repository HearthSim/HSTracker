class ZoneHandler
  def self.handle(line)
    if (match = /ProcessChanges.*TRANSITIONING card \[name=(.*).*zone=PLAY.*cardId=(.*).*player=(\d)\] to (.*) \(Hero\)/i.match(line))

      card_id = match[2].strip
      to = match[4]

      if to =~ /FRIENDLY PLAY/
        Game.instance.player_hero(card_id)
      else
        Game.instance.opponent_hero(card_id)
      end
    end
  end
end