class CardType
  INVALID = 0
  GAME = 1
  PLAYER = 2
  HERO = 3
  MINION = 4
  ABILITY = 5
  ENCHANTMENT = 6
  WEAPON = 7
  ITEM = 8
  TOKEN = 9
  HERO_POWER = 10

  class << self
    def parse(value)
      values.fetch(value, value)
    end

    def values
      {
        'INVALID' => INVALID,
        'GAME' => GAME,
        'PLAYER' => PLAYER,
        'HERO' => HERO,
        'MINION' => MINION,
        'ABILITY' => ABILITY,
        'ENCHANTMENT' => ENCHANTMENT,
        'WEAPON' => WEAPON,
        'ITEM' => ITEM,
        'TOKEN' => TOKEN,
        'HERO_POWER' => HERO_POWER,
      }
    end
  end
end
