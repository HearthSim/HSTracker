class RachelleHandler
  def self.handle(line)
    if (match = /(\d)\/3 wins towards 10 gold/.match(line))
        victories = match[1].to_i
        log(:analyzer, "#{victories} / 3 -> 10 gold")
      end

      if (match = /.*somehow the card def for (\w+_\w+) was already in the cache\.\.\./.match(line))
        card_id = match[1]
        #if @game_mode == :arena
        #  log(:analyzer, "possible arena card draft : #{card_id} ?")
        #else
        #  log(:analyzer, "possible constructed card draft : #{card_id} ?")
        #end

      end
  end
end