class DeckManager < NSWindowController

  def init
    super.tap do
      @layout              = DeckManagerLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @table_view = @layout.get(:table_view)
      @table_view.setHeaderView nil
      #@table_view.delegate   = self
      #@table_view.dataSource = self

      @new_deck = @layout.get(:new_deck)
      @new_deck.setTarget self
      @new_deck.setAction 'add_deck:'
    end
  end

  def add_deck(_)

  end

end