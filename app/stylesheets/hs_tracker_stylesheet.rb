class HSTrackerStylesheet < RubyMotionQuery::Stylesheet
  def self.center_in_screen(width, height)
    frame = NSScreen.mainScreen.frame
    w = frame.size.width
    h = frame.size.height
    [(w / 2) - (width / 2), (h / 2) - (height / 2)]
  end
end
