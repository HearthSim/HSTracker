class AssetHandler
  def self.handle(line)
    if Game.instance.awaiting_ranked_detection
        Game.instance.last_asset_unload = NSDate.new.timeIntervalSince1970
        Game.instance.awaiting_ranked_detection = false
      end

      if (match = /Medal_Ranked_(\d+)/.match(line))
        rank = match[1].to_i
        Game.instance.player_rank(rank)

      elsif line.include? 'rank_window'
        Game.instance.found_ranked = true
        Game.instance.game_mode = :ranked

      elsif (match = /unloading name=(\w+_\w+) family=CardPrefab persistent=False/.match(line))
        card_id = match[1]
        #if @game_mode == :arena
        #  log(:analyzer, "possible arena card draft : #{card_id} ?")
        #else
        #  log(:analyzer, "possible constructed card draft : #{card_id} ?")
        #end

      elsif line =~ /unloading name=Tavern_Brawl/
        Game.instance.game_mode = :brawl
      end
  end
end