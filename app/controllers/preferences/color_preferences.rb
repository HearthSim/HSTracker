class ColorPreferences < NSViewController

  def init
    super.tap do
      @layout = ColorPreferencesLayout.new
      self.view = @layout.view
    end
  end

  def view
    @layout.view
  end

  # MASPreferencesViewController
  def identifier
    'ColorsPreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNameAdvanced)
  end

  def toolbarItemLabel
    :colors._
  end
end
