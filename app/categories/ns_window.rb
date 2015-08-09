class NSWindow
  def show_sheet(window)
    if self.respond_to? 'beginSheet:completionHandler:'
      self.beginSheet(window, completionHandler: nil)
    else
      NSApp.beginSheet(window,
                       modalForWindow: self,
                       modalDelegate: self,
                       didEndSelector: nil,
                       contextInfo: nil)
    end
  end

  def end_sheet(return_code)
    if self.respond_to? 'sheetParent'
      self.sheetParent.endSheet(self, returnCode: return_code)
    else
      NSApp.endSheet(self, returnCode: NSModalResponseContinue)
      self.orderOut(nil)
    end
  end
end
