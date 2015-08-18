class DownloaderLayout < MK::WindowLayout
  def layout

    h = CGRectGetMidY(NSScreen.mainScreen.frame)
    w = CGRectGetMidX(NSScreen.mainScreen.frame)

    frame [[w - 150, h - 50], [300, 100]]
    title :downloading._
    style_mask NSBorderlessWindowMask | NSTitledWindowMask

    add NSTextField, :message do
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:superview).plus(10)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSProgressIndicator, :progress_bar do
      indeterminate true
      usesThreadedAnimation true
      minValue 0

      constraints do
        height.is 20
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
        top.equals(:message, :bottom).plus(10)
      end
    end
  end
end
