class PreferencesLayout < MK::Layout
  def options
    {}
  end

  def layout
    frame [[0, 0], [300, 250]]

    prev = :superview
    options.each do |key, opts|

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
            right.equals(:superview).minus(20)
          end
        end
        prev = :"#{key}_label"
      end

      elem = add opts[:type], :"#{key}" do
        if opts[:title]
          title opts[:title]
        end

        constraints do
          height 26

          if prev == :superview
            top.equals(prev).plus(10)
          else
            top.equals(prev, :bottom).plus(10)
          end
          left.equals(:superview).plus(20)
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

    opts = options[identifier]
    return if opts.nil?

    if opts[:changed]
      opts[:changed].call(sender)
    end
  end
end