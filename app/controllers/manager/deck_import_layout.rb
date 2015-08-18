class DeckImportLayout < MK::WindowLayout

  def layout
    frame_width = 390
    frame_height = 200

    frame [[0, 0], [frame_width, frame_height]]
    title :import_deck._

    add NSTextField, :deck_label do
      stringValue :deck_url._
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:superview).plus(10)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :deck_label_info do
      stringValue Importer.supported_sites
      editable false
      bezeled false
      draws_background false

      constraints do
        top.equals(:deck_label, :bottom).plus(10)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :deck_id do
      constraints do
        top.equals(:deck_label_info, :bottom).plus(10)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSProgressIndicator, :indicator do
      style NSProgressIndicatorSpinningStyle
      controlSize NSSmallControlSize
      displayedWhenStopped false

      constraints do
        top.equals(:deck_id, :bottom).plus(20)
        left.equals(:superview).plus(20)
      end
    end

    add NSButton, :import do
      title :import._
      bezelStyle NSTexturedRoundedBezelStyle

      constraints do
        top.equals(:deck_id, :bottom).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSButton, :cancel do
      title :cancel._
      bezelStyle NSTexturedRoundedBezelStyle

      constraints do
        top.equals(:deck_id, :bottom).plus(20)
        right.equals(:import, :left).minus(10)
      end
    end

    add NSTextField, :status do
      stringValue :loading._
      editable false
      bezeled false
      draws_background false
      hidden true

      constraints do
        height 17

        bottom.equals(:indicator, :bottom)
        left.equals(:indicator, :right).plus(20)
        #right.equals(:cancel, :left).minus(10)
      end
    end

  end

end
