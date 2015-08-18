class Exporter

  # export all decks to files
  def self.export_to_files(dir)
    Deck.where(:is_active => true).or(:is_active).eq(nil).each do |deck|
      name = deck.name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
      puts "Saving #{deck.name} to #{dir}/#{name}.txt"
      File.open "#{dir}/#{name}.txt", 'w' do |file|
        text = deck.cards.map do |card|
          c = Card.by_id(card.card_id)

          "#{card.count} #{c.english_name}"
        end.join("\n")

        file.write text
      end
    end

    NSAlert.alert(:save._,
                  buttons: [:ok._],
                  informative: :all_decks_saved._
    )
  end
end
