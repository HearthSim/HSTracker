class LoadingScreenLayout < MK::WindowLayout
  def layout
    width  312
    height 311
    frame from_center(NSScreen.mainScreen, size: [312, 311])

    style_mask NSBorderlessWindowMask
    level NSFloatingWindowLevel

    opaque false
    has_shadow false
    background_color :clear.nscolor

    add NSImageView do
      image NSImage.alloc.initByReferencingFile "#{'images/'.resource_path}/loading.png"

      constraints do
        width.equals(:superview)
        height.equals(:superview)
      end
    end
  end
end