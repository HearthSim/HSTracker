module Database

  def init_database(&block)
    cdq.setup

    # load cards into database if needed
    DatabaseGenerator.init_database(splash_screen) do

      # upgrade decks to have versions number
      Deck.upgrade_versions

      block.call if block
    end
  end

end
