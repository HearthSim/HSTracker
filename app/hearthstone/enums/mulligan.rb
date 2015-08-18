class Mulligan
  INVALID = 0
  INPUT = 1
  DEALING = 2
  WAITING = 3
  DONE = 4

  class << self
    def parse(value)
      values.fetch(value, value)
    end

    def values
      {
        'INVALID' => INVALID,
        'INPUT' => INPUT,
        'DEALING' => DEALING,
        'WAITING' => WAITING,
        'DONE' => DONE
      }
    end
  end
end
