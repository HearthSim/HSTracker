class NSArray

  # [160, 210, 242].nscolor => 0xA0D2F2.nscolor
  def nscolor(alpha=1.0)
    red = self[0] / 255.0
    green = self[1] / 255.0
    blue = self[2] / 255.0
    if self[3]
      alpha = self[3]
    end
    if NSColor.respond_to? 'colorWithRed:green:blue:alpha'
      NSColor.colorWithRed(red, green:green, blue:blue, alpha:alpha.to_f)
    else
      NSColor.colorWithCalibratedRed(red, green:green, blue:blue, alpha:alpha.to_f)
    end
  end

  # count cards in a deck
  def count_cards
    self.map(&:count).inject(0, :+)
  end

  # sort a deck
  # sort by
  # 1) card cost
  # 2) card type (spell, minion, ...)
  # 3) card name
  def sort_cards!
    sort! do |a, b|
      if a.cost != b.cost
        a.cost <=> b.cost
      elsif a.card_type != b.card_type
        b.card_type <=> a.card_type
      else
        a.name <=> b.name
      end
    end
  end


end