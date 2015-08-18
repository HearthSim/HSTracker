# General tab of the preferences
class GeneralPreferences < NSViewController

  def init
    super.tap do
      @layout = GeneralPreferencesLayout.new
      self.view = @layout.view
    end
  end

  def view
    @layout.view
  end

  # MASPreferencesViewController
  def identifier
    'GeneralPreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNamePreferencesGeneral)
  end

  def toolbarItemLabel
    :general._
  end
end
