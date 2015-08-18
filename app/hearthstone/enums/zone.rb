class Zone
  INVALID = -1
  CREATED = 0
  PLAY = 1
  DECK = 2
  HAND = 3
  GRAVEYARD = 4
  REMOVEDFROMGAME = 5
  SETASIDE = 6
  SECRET = 7

  class << self
    def parse(value)
      values.fetch(value, value)
    end

    def values
      {
        'INVALID' => INVALID,
        'CREATED' => CREATED,
        'PLAY' => PLAY,
        'DECK' => DECK,
        'HAND' => HAND,
        'GRAVEYARD' => GRAVEYARD,
        'REMOVEDFROMGAME' => REMOVEDFROMGAME,
        'SETASIDE' => SETASIDE,
        'SECRET' => SECRET,
      }
    end
  end
end
