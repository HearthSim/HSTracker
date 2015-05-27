class Exporter

  # export all decks to files
  def self.export_to_files(dir)
    Deck.where(:is_active => true).or(:is_active).eq(nil).each do |deck|
      name = deck.name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
      puts "Saving #{deck.name} to #{dir}/#{name}.txt"
      File.open "#{dir}/#{name}.txt", 'w' do |file|
        text = ''
        deck.cards.each do |card|
          c = Card.by_id(card.card_id)

          text << "#{card.count} #{c.english_name}\n"
        end

        file.write text
      end
    end

    NSAlert.alert('Save'._,
                  :buttons     => ['OK'._],
                  :informative => 'All deck have been saved'._
    )
  end
end