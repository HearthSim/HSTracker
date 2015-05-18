class NSWindow
  def show_sheet(window)
    if self.respond_to? 'beginSheet:completionHandler:'
      self.beginSheet(window, completionHandler: nil)
    else
      NSApp.beginSheet(window,
                       modalForWindow: self,
                       modalDelegate:  self,
                       didEndSelector: 'sheetDidEnd:returnCode:contextInfo:',
                       contextInfo:    nil)
    end
  end

  def sheetDidEnd(sheet, returnCode: _, contextInfo: _)
    sheet.orderOut self
  end

  def end_sheet(return_code)
    if self.respond_to? 'sheetParent'
      self.sheetParent.endSheet(self, returnCode: return_code)
    else
      NSApp.endSheet(self)
      self.orderOut(nil)
    end
  end
end