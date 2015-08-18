class DeckStatsView < NSView

  attr_accessor :deck

  def deck=(value)
    @deck = value

    setNeedsDisplay true
  end

  def drawRect(rect)
    super.tap do
      return if deck.nil?

      text = ''

      total = deck.statistics.count
      if total > 0
        win = deck.statistics.where(:win => true).count
        percent_win = win.to_f / total.to_f * 100.0

        text << :show_stat._(percent: percent_win.round(2), win: win, total: total)
        text << "\n"
      end

      if deck.deck.nil?
        num_version = Deck.where(:deck => deck).count
      else
        num_version = Deck.where(:deck => deck.deck).count
      end
      num_version += 1
      text << :show_versions._(number: num_version)

      text.attrd
        .foreground_color(:black.nscolor)
        .font('Belwe Bd BT'.nsfont(16.0))
        .drawInRect rect
    end
  end

end
