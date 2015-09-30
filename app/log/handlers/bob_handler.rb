class BobHandler
  def self.handle(line)
    return unless line.include?('---Register')

    if line.include?('---RegisterScreenBox---')
      if Game.instance.game_mode == :spectator
        Game.instance.game_end
      end
    elsif line.include?('---RegisterScreenForge---')
      Game.instance.game_mode = :arena
    elsif line.include?('---RegisterScreenPractice---')
      Game.instance.game_mode = :practice
    elsif line.include?('---RegisterScreenTourneys---')
      Game.instance.game_mode = :casual
    elsif line.include?('---RegisterScreenFriendly---')
      Game.instance.game_mode = :friendly
    end
  end
end
