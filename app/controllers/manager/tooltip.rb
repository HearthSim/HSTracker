class Tooltip < NSViewController
  attr_accessor :card

  def init
    super.tap do
      @layout = TooltipLayout.new
      self.view = @layout.view

      @card_label = @layout.get(:card_label)
    end
  end

  def view
    @layout.view
  end

  def card=(card)
    @card = card

    text = ''
    if card.name
      text = card.name.bold.underline.font('Belwe Bd BT'.nsfont(15))
    end

    options = { NSDocumentTypeDocumentAttribute => NSHTMLTextDocumentType }

    if card.text
      card_text = card.text.dup

      # replace text
      card_text.gsub! /\$(\d+) \|4\((\w+),(\w+)\)/ do |_|
        single = $2
        plural = $3
        count = $1.gsub(/\$/, '').to_i
        "#{count} #{count <= 1 ? single : plural}"
      end
      card_text.gsub! /\$/, ''

      text += NSAttributedString.alloc
                .initWithData("<br><br>#{card_text}".dataUsingEncoding(NSUnicodeStringEncoding), options: options, documentAttributes: nil, error: nil)
                .font('FranklinGothic-Book'.nsfont(15))
    end

    if card.flavor

      paragraph = NSMutableParagraphStyle.alloc.init
      paragraph.setAlignment NSCenterTextAlignment
      line = ''.attrd.paragraph_style(paragraph).font('TypeEmbellishmentsOneLetPlain'.nsfont(24))

      text += "\n".attrd + line + "\n".attrd
      text += card.flavor.attrd
                .font('FranklinGothic-BookItalic'.nsfont(14))
    end

    @card_label.textStorage.setAttributedString text
    @card_label.sizeToFit
  end

  def text_height
    CGRectGetHeight(@card_label.frame) + 20
  end
end
