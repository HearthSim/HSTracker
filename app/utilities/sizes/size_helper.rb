class SizeHelper

  def self.player_tracker_frame
    width = case Configuration.card_layout
              when :small
                TrackerLayout::KSmallFrameWidth
              when :medium
                TrackerLayout::KMediumFrameWidth
              else
                TrackerLayout::KFrameWidth
            end
    hearthstone_window = OSXHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    point = OSXHelper.point_relative_to_hearthstone([hearthstone_window.size.width - width, 0])
    size = [width, hearthstone_window.size.height]
    [point, size]
  end

  def self.opponent_tracker_frame
    width = case Configuration.card_layout
              when :small
                TrackerLayout::KSmallFrameWidth
              when :medium
                TrackerLayout::KMediumFrameWidth
              else
                TrackerLayout::KFrameWidth
            end
    hearthstone_window = OSXHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    point = OSXHelper.point_relative_to_hearthstone([0, 0])
    return nil if point.nil?
    size = [width, hearthstone_window.size.height]
    [point, size]
  end

  def self.timer_hud_frame
    hearthstone_window = OSXHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    size = [100, 80]
    point = [hearthstone_window.size.width - 300 - size[0], hearthstone_window.size.height / 2 + 20]
    point = OSXHelper.point_relative_to_hearthstone(point)
    [point, size]
  end

  def self.player_card_count_frame
    hearthstone_window = OSXHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    size = [225, 60]
    point = [hearthstone_window.size.width - 435 - size[0], 275]
    point = OSXHelper.point_relative_to_hearthstone(point)
    [point, size]
  end

  def self.opponent_card_count_frame
    hearthstone_window = OSXHelper.hearthstone_frame
    return nil if hearthstone_window.nil?

    size = [225, 40]
    point = [415, hearthstone_window.size.height - 255]
    point = OSXHelper.point_relative_to_hearthstone(point)
    [point, size]
  end
end
