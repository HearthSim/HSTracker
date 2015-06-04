class SyncPreferences < NSViewController

  def init
    super.tap do
      @layout   = SyncPreferencesLayout.new
      self.view = @layout.view
    end
  end

  def view
    @layout.view
  end

  # MASPreferencesViewController
  def identifier
    'SyncPreferences'
  end

  def toolbarItemImage
    NSImage.imageNamed(NSImageNameUserAccounts)
  end

  def toolbarItemLabel
    'User Accounts'._
  end
end