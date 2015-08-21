class LoadingScreenLayout < MK::WindowLayout
  def layout
    width 312
    height 311
    frame from_center(NSScreen.mainScreen, size: [350, 250])

    style_mask NSBorderlessWindowMask
    level NSFloatingWindowLevel

    opaque false
    has_shadow false

    add NSImageView, :bg do
      image NSImage.alloc.initByReferencingFile "#{'images/assets/'.resource_path}/loading.jpg"

      constraints do
        width.equals(:superview)
        height.equals(:superview)
      end
    end

    add NSProgressIndicator, :progress do
      indeterminate false
      style NSProgressIndicatorBarStyle
      setWantsLayer true

      constraints do
        height 30

        bottom.equals(:superview).minus(25)
        left.equals(:superview).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :label do
      editable false
      bezeled false
      draws_background false
      text_color :white.nscolor

      constraints do
        height 35

        top.equals(:progress, :bottom).minus(5)
        left.equals(:superview).plus(25)
        right.equals(:superview).minus(25)
      end
    end
  end
end
