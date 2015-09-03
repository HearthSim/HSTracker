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

    #[[1100, 470], [100, 80]]
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

  def self.opponent_card_hud_frame(position, card_count)
    point = case card_count
              when 1
                [684.0, 785.0]
              when 2
                case position
                  when 0
                    [638.0, 785.0]
                  when 1
                    [728.0, 785.0]
                  else
                    nil
                end
              when 3
                case position
                  when 0
                    [593.0, 800.0]
                  when 1
                    [683.0, 785.0]
                  when 2
                    [773.0, 800.0]
                  else
                    nil
                end
              when 4
                case position
                  when 0
                    [578.0, 800.0]
                  when 1
                    [648.0, 785.0]
                  when 2
                    [718.0, 785.0]
                  when 3
                    [788.0, 795.0]
                  else
                    nil
                end
              when 5
                case position
                  when 0
                    [563.0, 800.0]
                  when 1
                    [618.0, 785.0]
                  when 2
                    [678.0, 780.0]
                  when 3
                    [733.0, 785.0]
                  when 4
                    [793.0, 800.0]
                  else
                    nil
                end
              when 6
                case position
                  when 0
                    [548.0, 810.0]
                  when 1
                    [598.0, 800.0]
                  when 2
                    [648.0, 785.0]
                  when 3
                    [693.0, 780.0]
                  when 4
                    [738.0, 785.0]
                  when 5
                    [798.0, 800.0]
                  else
                    nil
                end
              when 7
                case position
                  when 0
                    [538.0, 805.0]
                  when 1
                    [588.0, 788.0]
                  when 2
                    [623.0, 780.0]
                  when 3
                    [663.0, 775.0]
                  when 4
                    [706.0, 780.0]
                  when 5
                    [748.0, 785.0]
                  when 6
                    [798.0, 800.0]
                  else
                    nil
                end
              when 8
                case position
                  when 0
                    [538.0, 810.0]
                  when 1
                    [578.0, 800.0]
                  when 2
                    [613.0, 790.0]
                  when 3
                    [648.0, 780.0]
                  when 4
                    [678.0, 775.0]
                  when 5
                    [718.0, 780.0]
                  when 6
                    [758.0, 785.0]
                  when 7
                    [798.0, 795.0]
                end
              when 9
                case position
                  when 0
                    [532.0, 810.0]
                  when 1
                    [566.0, 800.0]
                  when 2
                    [598.0, 788.0]
                  when 3
                    [628.0, 782.0]
                  when 4
                    [663.0, 778.0]
                  when 5
                    [693.0, 778.0]
                  when 6
                    [726.0, 782.0]
                  when 7
                    [758.0, 790.0]
                  when 8
                    [808.0, 805.0]
                  else
                    nil
                end
              when 10
                case position
                  when 0
                    [518.0, 810.0]
                  when 1
                    [558.0, 810.0]
                  when 2
                    [588.0, 795.0]
                  when 3
                    [618.0, 785.0]
                  when 4
                    [643.0, 780.0]
                  when 5
                    [673.0, 775.0]
                  when 6
                    [703.0, 775.0]
                  when 7
                    [733.0, 780.0]
                  when 8
                    [763.0, 790.0]
                  when 9
                    [803.0, 805.0]
                end
              else
                nil
            end

    if point.nil?
      point = [0, 0]
    else
      point[1] = point[1] - 40 - 22
    end
    size = [40, 80]
    point = OSXHelper.point_relative_to_hearthstone(point)

    [point, size]
  end
end
