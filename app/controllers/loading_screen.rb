class LoadingScreen < NSWindowController

  def init
    super.tap do
      @layout = LoadingScreenLayout.new
      self.window = @layout.window

      @image = @layout.get(:bg)
      @progress = @layout.get(:progress)
      @label = @layout.get(:label)
    end
  end

  def max(total)
    @progress.minValue = 0
    @progress.maxValue = total
    @progress.doubleValue = 0
  end

  def progress(text)
    @progress.doubleValue = @progress.doubleValue + 1.0
    @label.stringValue = text
    @progress.displayIfNeeded
  end

  def text(text)
    @progress.indeterminate = true
    @progress.startAnimation(self)
    @label.stringValue = text
  end

end
