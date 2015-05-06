class Exporter

  # export all decks to files
  def self.export_to_files
    Deck.where(:is_active => true).or(:is_active).eq(nil).each do |deck|
      name = deck.name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

      File.open "/Desktop/#{name}.txt".home_path, 'w' do |file|
        text = ''
        deck.cards.each do |card|
          c = Card.by_id(card.card_id)

          text << "#{card.count} #{c.english_name}"
          text << "\n"
        end

        file.write text
      end
    end
  end
end