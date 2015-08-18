class HearthStatsRegisterLayout < MK::WindowLayout

  def layout
    frame_width = 485
    frame_height = 300

    width frame_width
    height frame_height
    frame from_center(NSScreen.mainScreen, size: [frame_width, frame_height])
    title :configure_hearthstats._

    style_mask NSTitledWindowMask

    add NSImageView, :logo do
      image 'hearthstats.png'.nsimage

      constraints do
        top.equals(:superview).plus(10)
        left.equals(:superview).plus(10)
        width.is 150
      end
    end

    add NSTextField, :login_label do
      stringValue :login._
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:superview).plus(10)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :login do
      constraints do
        top.equals(:login_label, :bottom).plus(5)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :confirm_login_label do
      stringValue :confirm_login._
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:login, :bottom).plus(10)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :confirm_login do
      constraints do
        top.equals(:confirm_login_label, :bottom).plus(5)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :password_label do
      stringValue :password._
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:confirm_login, :bottom).plus(10)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSSecureTextField, :password do
      constraints do
        top.equals(:password_label, :bottom).plus(5)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSTextField, :confirm_password_label do
      stringValue :confirm_password._
      editable false
      bezeled false
      draws_background false

      constraints do
        height 17

        top.equals(:password, :bottom).plus(10)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSSecureTextField, :confirm_password do
      constraints do
        top.equals(:confirm_password_label, :bottom).plus(5)
        left.equals(:logo, :right).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSButton, :register do
      title :register._
      bezelStyle NSTexturedRoundedBezelStyle

      constraints do
        top.equals(:confirm_password, :bottom).plus(20)
        right.equals(:superview).minus(20)
      end
    end

    add NSButton, :cancel do
      title :cancel._
      bezelStyle NSTexturedRoundedBezelStyle

      constraints do
        top.equals(:confirm_password, :bottom).plus(20)
        right.equals(:register, :left).minus(10)
      end
    end
  end

end
