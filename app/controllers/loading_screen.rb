class LoadingScreen < NSWindowController

  def init
    super.tap do
      @layout     = LoadingScreenLayout.new
      self.window = @layout.window
    end
  end

end