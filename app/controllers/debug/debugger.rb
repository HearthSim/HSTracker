class Debugger < NSWindowController
  def init
    super.tap do
      @layout              = DebuggerLayout.new
      self.window          = @layout.window

      @text_view = @layout.get(:text_view)

      @debug = @layout.get(:debug)
      @debug.setTarget self
      @debug.setAction 'debug:'
    end
  end

  def debug(_)
    Hearthstone.instance.start_from_debugger(@text_view.textStorage.string)
  end
end