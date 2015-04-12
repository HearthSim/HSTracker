class LoadingScreen < NSWindowController

  def init
    super.tap do
      @layout     = LoadingScreenLayout.new
      self.window = @layout.window

      @progress = @layout.get(:progress)
    end
  end

  def max(total)
    @progress.minValue = 0
    @progress.maxValue = total
    @progress.doubleValue = 0
  end

  def progress
    @progress.incrementBy 1.0
  end

end