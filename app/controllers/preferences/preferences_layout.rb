class PreferencesLayout < MK::Layout
  def options
    {}
  end

  def frame_size
    [[0, 0], [450, 400]]
  end

  def layout
    frame frame_size

    prev = :superview
    normalized_options.each do |key, opts|
      left_prev = :superview

      if opts[:label]
        add NSTextField, :"#{key}_label" do

          stringValue opts[:label]
          editable false
          bezeled false
          draws_background false

          constraints do
            height 17

            if prev == :superview
              top.equals(prev).plus(10)
            else
              top.equals(prev, :bottom).plus(10)
            end
            left.equals(:superview).plus(20)
          end
        end
        left_prev = :"#{key}_label"
      end

      elem = add opts[:type], key.to_sym do
        if opts[:title]
          title opts[:title]
        end

        if opts[:type] == NSButton
          set_button_type NSMomentaryPushInButton
          set_bezel_style NSRoundedBezelStyle
        end

        if opts.has_key?(:enabled)
          enabled opts[:enabled]
        end

        constraints do
          height 26

          if opts[:type] == NSColorWell
            width.equals 50
          end

          if prev == :superview
            top.equals(prev).plus(10)
          else
            top.equals(prev, :bottom).plus(5)
          end
          if left_prev == :superview
            left.equals(:superview).plus(20)
          else
            left.equals(left_prev, :right).plus(10)
          end
          right.equals(:superview).minus(20)
        end
      end

      if opts[:init]
        opts[:init].call(elem)
      end

      elem.setTarget self
      elem.setAction 'option_changed:'
      elem.identifier = key

      prev = :"#{key}"

    end
  end

  def option_changed(sender)
    identifier = sender.identifier
    if identifier
      identifier = identifier.to_sym
    end

    opts = normalized_options[identifier]
    return if opts.nil?

    if opts[:changed]
      opts[:changed].call(sender)
    end
  end

  private
  def normalized_options
    normalized = {}
    options.each do |key, opts|
      if opts.is_a? String
        normalized[key] = {
          type: NSButton,
          title: opts,
          init: -> (elem) {
            elem.buttonType = NSSwitchButton
            elem.state = (Configuration.send(key.to_s) ? NSOnState : NSOffState)
          },
          changed: -> (elem) {
            Configuration.send("#{key.to_s}=", (elem.state == NSOnState))
          }
        }
      else
        normalized[key] = opts
      end
    end

    normalized
  end
end
