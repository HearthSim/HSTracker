class CurveView < NSView
  attr_accessor :cards

  def cards=(value)
    @cards = value

    # let's count that stuff
    @counts = {}
    @cards.each do |card|
      cost = card.cost
      if cost > 7
        cost = 7
      end

      unless @counts.has_key? cost
        @counts[cost] = {
          count: 0,
          minion: 0,
          spell: 0,
          weapon: 0
        }
      end
      @counts[cost][:count] += card.count
      @counts[cost][card.card_type.to_sym] += card.count
    end

    setNeedsDisplay true
  end

  def drawRect(rect)
    super.tap do
      return if @cards.count.zero?

      bar_width = (CGRectGetWidth(rect) / 8).floor
      padding = (CGRectGetWidth(rect) - (bar_width * 8)) / 8
      bar_height = CGRectGetHeight(rect) - (padding * 4) - 25

      mana_height = 25

      x = 0

      types = {
        minion: [[106, 210, 199].nscolor, [167, 231, 229].nscolor],
        spell: [[234, 107, 85].nscolor, [233, 156, 148].nscolor],
        weapon: [[138, 228, 113].nscolor, [206, 230, 184].nscolor]
      }

      # get the biggest value
      biggest = @counts.max_by { |_, v| v[:count] }[1][:count]
      # and get a unit based on this value
      one_unit = bar_height / biggest

      style = NSMutableParagraphStyle.new
      style.alignment = NSCenterTextAlignment

      (0...8).each do |count|
        NSGraphicsContext.saveGraphicsState

        x += padding

        mana = ImageCache.asset 'mana'
        mana.drawInRect([[x, padding], [mana_height, mana_height]],
                        fromRect: NSZeroRect,
                        operation: NSCompositeSourceOver,
                        fraction: 1.0)

        cost = "#{count}".attrd.paragraph_style(style)
                 .foreground_color(:white.nscolor)
                 .stroke_color(:black.nscolor)
                 .font('Belwe Bd BT'.nsfont(20.0))
                 .stroke_width(-1.5)
        cost_x = x + 1
        if count == 7
          cost_x = x - 4
        end
        cost.drawInRect [[cost_x, padding + 6], [mana_height, mana_height + 2]]
        if count == 7
          cost = '+'.attrd.paragraph_style(style)
                   .foreground_color(:white.nscolor)
                   .stroke_color(:black.nscolor)
                   .stroke_width(-1.5)
                   .bold(22)
          cost.drawInRect [[x + 5, padding + 3], [mana_height, mana_height + 2]]
        end

        current = { :count => 0 }
        if @counts.has_key? count
          current = @counts[count]
        end

        how_many = current[:count]
        unless how_many.zero?
          y = padding * 2 + mana_height
          types.each do |type, colors|
            if !current.has_key?(type) || current[type].zero?
              next
            end

            bar_rect = [[x, y], [bar_width, current[type] * one_unit]]
            y += current[type] * one_unit

            path = NSBezierPath.bezierPathWithRoundedRect(bar_rect, xRadius: 0, yRadius: 0)


            gradient = NSGradient.alloc.initWithColors(colors,
                                                       atLocations: [0.0, 1.0].to_pointer(:double),
                                                       colorSpace: NSColorSpace.genericRGBColorSpace)

            gradient.drawInBezierPath(path, angle: 270)

          end
          count_cards = "#{how_many}".attrd.paragraph_style(style)
                          .foreground_color(:white.nscolor)
                          .stroke_color(:black.nscolor)
                          .font('Belwe Bd BT'.nsfont(20.0))
                          .stroke_width(-1.5)
          count_cards.drawInRect [[x, padding * 2 + mana_height + (how_many * one_unit) - 20], [bar_width, 30]]
        end
        x += bar_width
        NSGraphicsContext.restoreGraphicsState
      end
    end
  end

end
