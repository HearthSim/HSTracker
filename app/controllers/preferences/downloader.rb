class Downloader < NSWindowController

  def init
    super.tap do
      @layout     = DownloaderLayout.new
      self.window = @layout.window

      @progress_bar = @layout.get(:progress_bar)
      @message      = @layout.get(:message)
    end
  end

  def download(&block)
    locale = Configuration.hearthstone_locale
    path   = ImageCache.image_path(locale)

    cards    = Card.playable.per_lang(locale)
    card_ids = []
    cards.each do |card|
      card_ids << { :id => card.card_id, :name => card.name }
    end
    card = Card.by_id 'GAME_005'
    card_ids << { :id => card.card_id, :name => card.name }

    langs = %w(deDE enUS esES frFR ptBR ruRU)

    unless langs.include? locale
      locale = case locale
                 when 'esMX'
                   'esES'
                 when 'ptPT'
                   'ptBR'
                 else
                   'enUS'
               end
    end

    count                  = cards.count
    @progress_bar.maxValue = count

    @progress_bar.indeterminate = false

    Dispatch::Queue.concurrent.async do
      card_ids.each_with_index do |card, index|

        Web.download(card[:id], locale, path) do
          Dispatch::Queue.main.async do
            @message.stringValue = card[:name]
            @progress_bar.incrementBy 1.0

            if index == count - 1
              block.call if block
            end
          end
        end
      end
    end
  end
end