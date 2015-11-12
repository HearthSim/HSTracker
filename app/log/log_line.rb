class LogLine
  attr_accessor :time, :namespace, :line

  def initialize(opts={})
    self.namespace = opts[:namespace]
    self.line = opts[:line]
    self.time = opts[:time]
  end

  def self.parse_time(time)
    time = time[2, 16].gsub(/\./, ':').split(':')
    return nil unless time.count == 4

    now = NSDate.now
    date = NSDate.from_components year: now.year,
                                  month: now.month,
                                  day: now.day,
                                  hour: time[0].to_i,
                                  minute: time[1].to_i,
                                  second: time[2].to_i,
                                  nanosecond: time[3].to_i

    if date > now
      date = date.delta(days: -1)
    end

    date.to_r
  end
end
