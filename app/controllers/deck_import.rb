# modal window to prompt the URL of a deck to import
class DeckImport < NSWindowController

  def init
    super.tap do
      @layout              = DeckImportLayout.new
      self.window          = @layout.window
      self.window.delegate = self

      @import = @layout.get(:import)
      @import.setTarget self
      @import.setAction 'import:'

      @cancel = @layout.get(:cancel)
      @cancel.setTarget self
      @cancel.setAction 'cancel:'
    end
  end

  def on_deck_loaded(&block)
    @deck_loaded_block = block
  end

  def import(_)
    if Configuration.locale.nil?
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.setMessageText('Error'._)
      alert.setInformativeText('You have not selected a language from the preferences, please choose a language before importing a deck'._)
      alert.setAlertStyle(NSCriticalAlertStyle)
      alert.beginSheetModalForWindow(self.window,
                                     modalDelegate:  self,
                                     didEndSelector: nil,
                                     contextInfo:    nil)
      return
    end

    indicator = @layout.get(:indicator)
    status    = @layout.get(:status)

    deck_id = @layout.get(:deck_id)

    deck = deck_id.stringValue

    @import.enabled = false
    deck_id.enabled = false

    if deck == ''
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('OK'._)
      alert.setMessageText('Error'._)
      alert.setInformativeText('Empty deck url'._)
      alert.setAlertStyle(NSCriticalAlertStyle)
      alert.beginSheetModalForWindow(self.window,
                                     modalDelegate:  self,
                                     didEndSelector: nil,
                                     contextInfo:    nil)

      @import.enabled = true
      deck_id.enabled = true

      return
    end

    indicator.startAnimation(self)
    status.hidden = false

    Importer.load deck do |cards, clazz, name|
      indicator.stopAnimation(self)
      status.hidden = false

      if cards
        @deck_loaded_block.call(cards, clazz, name) if @deck_loaded_block
        self.window.sheetParent.endSheet(self.window, returnCode: NSModalResponseOK)
      else
        alert = NSAlert.alloc.init
        alert.addButtonWithTitle('OK'._)
        alert.setMessageText('Error'._)
        alert.setInformativeText('Error while loading deck'._)
        alert.setAlertStyle(NSCriticalAlertStyle)
        alert.beginSheetModalForWindow(self.window,
                                       modalDelegate:  self,
                                       didEndSelector: nil,
                                       contextInfo:    nil)

        @import.enabled = true
        deck_id.enabled = true
      end
    end
  end

  def cancel(_)
    self.window.sheetParent.endSheet(self.window, returnCode: NSModalResponseCancel)
  end

end