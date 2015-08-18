class StatisticPanel < NSWindowController

  attr_accessor :deck

  def init
    super.tap do
      @layout = StatisticPanelLayout.new
      self.window = @layout.window

      @table_view = @layout.get(:table_view)

      @table_view.delegate = self
      @table_view.dataSource = self

      @close = @layout.get(:close)
      @close.setTarget self
      @close.setAction 'close_panel:'
    end
  end

  def close_panel(_)
    self.window.end_sheet(NSModalResponseOK)
  end

  def deck=(value)
    @deck = value
    if value.deck.nil?
      versions = [value] + Deck.where(:deck => value).to_a
    else
      versions = [value.deck] + Deck.where(:deck => value.deck).to_a
    end
    @version = versions.size

    @stats = []
    versions.sort { |a, b| b.version <=> a.version }.each do |deck_version|
      # can be nil for old decks
      deck_version_nbr = deck_version.version || 0
      version = { 'version' => "v#{deck_version_nbr}" }

      deck_version.statistics.each do |stat|
        clazz = stat.opponent_class

        unless version[clazz]
          version[clazz] = { win: 0, total: 0, percent: 0 }
        end

        version[clazz][:win] += 1 if stat.win.to_bool
        version[clazz][:total] += 1

        win = version[clazz][:win]
        loss = version[clazz][:total] - win
        version[clazz][:percent] = "#{(version[clazz][:win].to_f / version[clazz][:total] * 100.0).round(2)}%\n#{win} - #{loss}"

      end

      @stats << version
    end

    @table_view.reloadData
  end

  def numberOfRowsInTableView(tableView)
    @version || 0
  end

  ## table delegate
  def tableView(table_view, viewForTableColumn: column, row: row)

    if @stats[row].has_key? column.identifier
      value = @stats[row][column.identifier]
      if value.is_a? Hash
        value = value[:percent]
      end
    else
      value = :n_a._
    end

    text_field = table_view.makeViewWithIdentifier(column.identifier, owner: self)

    unless text_field
      text_field = NSTextField.alloc.initWithFrame([[0, 0], [column.width, 0]])
      text_field.identifier = column.identifier
      text_field.editable = false
      text_field.drawsBackground = false
      text_field.bezeled = false
      text_field.alignment = NSCenterTextAlignment
    end

    text_field.stringValue = value

    text_field
  end
end
