class LoadingScreenLayout < MK::WindowLayout
  def layout
    width 312
    height 311
    frame from_center(NSScreen.mainScreen, size: [312, 311])

    style_mask NSBorderlessWindowMask
    level NSFloatingWindowLevel

    opaque false
    has_shadow false
    background_color :clear.nscolor

    add NSImageView do
      setWantsLayer true
      layer.setBackgroundColor :clear.nscolor
      image NSImage.alloc.initByReferencingFile "#{'images/assets/'.resource_path}/loading.png"

      constraints do
        width.equals(:superview)
        height.equals(:superview)
      end
    end

    add NSProgressIndicator, :progress do
      indeterminate false
      style NSProgressIndicatorBarStyle

      constraints do
        height 20

        bottom.equals(:superview).minus(80)
        left.equals(:superview).plus(90)
        right.equals(:superview).minus(110)
      end
    end
  end
end
