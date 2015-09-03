module Kernel
  def error(type, data={})
    _message(:error, type, data)
  end

  def log(type, data={})
    _message(:log, type, data)
  end

  def log_file_content
    content = NSData.read_from(log_file)
    return nil if content.nil?

    lines = content.to_s.split("\n")
    lines[-([200, lines.count - 1].min)..-1].join("\n")
  end

  private
  def _message(level, type, data={})
    date = NSDate.now.string_with_format(:iso8601)
    case RUBYMOTION_ENV
      when 'test'
        puts "[#{date}][#{type}][#{level}]: #{data.inspect}"
      when 'development'
        args = { date: date,
                 type: type,
                 data: data
        }
        mp args, force_color: level == :log ? nil : :red
      else
        File.open(log_file, 'a') { |file| file << "[#{date}][#{type}][#{level}]: #{data.inspect}\n" }
    end
  end

  def log_file
    @file ||= begin
      date = NSDate.now
      five_days = date.delta(days: -5)

      log_dir = "/Library/Logs/HSTracker".home_path
      Dir.mkdir(log_dir) unless Dir.exists?(log_dir)

      Dir.glob("#{log_dir}/*.log").each do |file|
        # old logs
        base_name = File.basename(file)

        if base_name =~ /^be\.michotte\.hstracker/
          File.delete(file)
          next
        end

        components = base_name.gsub(/\.log/, '').split('-')
        file_date = NSDate.from_components(year: components[0], month: components[1], day: components[2])
        file_size = File.size(file)
        if file_size > 10000000 || file_date < five_days
          File.delete(file)
          next
        end
      end

      "/Library/Logs/HSTracker/#{date.date_array.join('-')}.log".home_path
    end
  end
end
