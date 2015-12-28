class LoadingScreen < ProMotion::WindowScreen
  stylesheet LoadingScreenStylesheet

  def on_load
    append(NSImageView, :bg)
    append(NSProgressIndicator, :progress)
    append(NSTextField, :label)
  end

  def max(total)
    find(:progress).style do |st|
      st.min = 0
      st.max = total
      st.value = 0
    end
  end

  def progress(text)
    find(:progress).data = find(:progress).data + 1.0
    find(:label).data = text
    #@progress.displayIfNeeded
  end

  def text(text)
    find(:progress).view.indeterminate = true
    find(:progress).view.startAnimation(self)
    find(:label).data = text
  end

end
