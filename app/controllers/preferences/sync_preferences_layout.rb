class SyncPreferencesLayout < PreferencesLayout

  def frame_size
    [[0, 0], [300, 350]]
  end

  def options
    {
        :use_hearthstats => 'Configure Hearthstats'._
    }
  end

end