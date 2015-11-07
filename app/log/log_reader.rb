class LogReader

  def initialize(name, log_reader_manager, opts={})
    @name = name
    @start_filters = opts[:starts_filters]
    @contains_filters = opts[:contains_filters]
    @log_reader_manager = log_reader_manager
    @path = File.join(Hearthstone.log_path, "#{name}.log")
  end

  def find_entry_point(str)
    time = NSDate.distantPast
    return time unless File.exists?(@path)

    IO.foreach(@path).reverse_each do |line|
      if line.include?(str)
        time = LogLine.parse_time(line) || File.mtime(@path)
        break
      end
    end

    time
  end

  def start(starting_point)
    @starting_point = starting_point
    @stop = false
    @offset = 0
    read_log_file
  end

  def read_log_file
    return if @stop

    if File.exists?(@path)
      file_handle = NSFileHandle.fileHandleForReadingAtPath(@path)
      file_handle.seekToFileOffset(@offset)

      data = file_handle.readDataToEndOfFile
      lines_str = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      @offset += lines_str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

      lines_str
        .split("\n")
        .delete_if { |line| line !~ /^D\s/ }
        .each do |line|

        time = LogLine.parse_time(line) || File.mtime(@path).to_f

        parse = false
        if @start_filters.nil? || @contains_filters.nil?
          parse = true
        elsif @start_filters
          parse = !(@start_filters.select { |filter| line[19..-1].start_with?(filter) }).empty?
        end
        if @contains_filters && !parse
          parse = !(@contains_filters.select { |filter| line[19..-1].include?(filter) }).empty?
        end

        if time >= @starting_point && parse
          log_line = LogLine.new(namespace: @name, line: line, time: time)
          @log_reader_manager.process_new_line(log_line)
        end

      end
    end

    Dispatch::Queue.main.after(LogReaderManager::TimeoutRead) do
      read_log_file
    end
  end

  def stop
    log :log_reader, stopping: @name
    @stop = true
  end

end
