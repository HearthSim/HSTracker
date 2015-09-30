class LogReader

  def initialize(name, opts={})
    @name = name
    @start_filters = opts[:starts_filters]
    @contains_filters = opts[:contains_filters]
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
    #if File.exists?(@path)
    #  File.delete(@path)
    #end

    @starting_point = starting_point
    @stop = false
    @offset = 0
    @lines = []

    @read_thread = NSThread.alloc.initWithTarget(self, selector: :read_log_file, object:nil)
    @read_thread.start
  end

  def read_log_file
    @running = true
    until @stop do

      file_handle = NSFileHandle.fileHandleForReadingAtPath(@path)
      if file_handle.nil?
        NSThread.sleepForTimeInterval(LogReaderManager::TimeoutRead)
        next
      end
      file_handle.seekToFileOffset(@offset)

      data = file_handle.readDataToEndOfFile
      lines_str = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      @offset += lines_str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

      lines = lines_str.split "\n"
      lines.each do |line|
        next unless line =~ /^D\s/

        time = LogLine.parse_time(line) || File.mtime(@path)

        parse = false
        if @start_filters.nil? || @contains_filters.nil?
          parse = true
        elsif @start_filters
          parse = !(@start_filters.select {|filter| line[19..-1].start_with?(filter) }).empty?
        end
        if @contains_filters && !parse
          parse = !(@contains_filters.select {|filter| line[19..-1].include?(filter) }).empty?
        end

        if time >= @starting_point && parse
          log_line = LogLine.new(namespace: @name, line: line, time: time)
          @lines << log_line
        end

      end

      NSThread.sleepForTimeInterval(LogReaderManager::TimeoutRead)
    end
  end

  def stop
    @stop = true
  end

  def collect
    lines = @lines
    @lines = []

    lines
  end

end
