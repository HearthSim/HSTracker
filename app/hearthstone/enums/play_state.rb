class PlayState
  INVALID = 0
  PLAYING = 1
  WINNING = 2
  LOSING = 3
  WON = 4
  LOST = 5
  TIED = 6
  DISCONNECTED = 7
  QUIT = 8

  class << self
    def parse(value)
      values.fetch(value, value)
    end

    def values
      {
        'INVALID' => INVALID,
        'PLAYING' => PLAYING,
        'WINNING' => WINNING,
        'LOSING' => LOSING,
        'WON' => WON,
        'LOST' => LOST,
        'TIED' => TIED,
        'DISCONNECTED' => DISCONNECTED,
        'QUIT' => QUIT
      }
    end
  end
end
