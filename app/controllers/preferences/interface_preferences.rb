class InterfacePreferences < NSViewController

  def init
    super.tap do
      @layout = InterfacePreferencesLayout.new
      self.view = @layout.view
    end
  end

  def view
    @layout.view
  end

  # MASPreferencesViewController
  def identifier
    'InterfacePreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNameColorPanel)
  end

  def toolbarItemLabel
    :interface._
  end
end
