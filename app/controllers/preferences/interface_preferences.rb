class InterfacePreferences < NSViewController

  def init
    super.tap do
      @layout   = InterfacePreferencesLayout.new
      self.view = @layout.view
    end
  end

  def view
    @layout.view
  end

  # MASPreferencesViewController
  def identifier
    'UIPreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNameAdvanced)
  end

  def toolbarItemLabel
    'Interface'._
  end
end