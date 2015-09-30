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

    date_components = NSDateComponents.new
    date_components.hour = time[0].to_i
    date_components.minute = time[1].to_i
    date_components.second = time[2].to_i
    date_components.nanosecond = time[3].to_i
    now = NSDate.now
    date_components.day = now.day
    date_components.month = now.month
    date_components.year = now.year

    calendar = NSCalendar.alloc.initWithCalendarIdentifier(NSGregorianCalendar)
    date = calendar.dateFromComponents(date_components)
    if date > now
      date = date.delta(days: -1)
    end

    date
  end
end
