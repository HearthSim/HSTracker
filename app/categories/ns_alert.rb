class NSAlert
  def self.alert(message, options={}, &block)
    buttons = options[:buttons]
    informative = options.fetch(:informative, nil)

    style = options.fetch(:style, NSInformationalAlertStyle)

    alert = NSAlert.new

    if buttons
      buttons.each do |button|
        alert.addButtonWithTitle(button)
      end
    end

    alert.setMessageText(message)
    if informative
      alert.setInformativeText(informative)
    end

    alert.setAlertStyle(style)

    view = options.fetch(:view, nil)
    if view
      alert.accessoryView = view
    end

    if options.fetch(:force_top, false)
      NSRunningApplication.currentApplication.activateWithOptions(NSApplicationActivateIgnoringOtherApps|NSApplicationActivateAllWindows)
      NSApplication.sharedApplication.activateIgnoringOtherApps(true)
    end

    window = options.fetch(:window, nil)
    if window && block
      if alert.respond_to? 'beginSheetModalForWindow:completionHandler:'
      alert.beginSheetModalForWindow(window,
                                     completionHandler: -> (return_code) {
                                       block.call(return_code)
                                     })
      else
        response = alert.runModal
        block.call(response)
      end
    else
      alert.runModal
    end
  end
end
