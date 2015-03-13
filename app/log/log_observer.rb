class LogObserver

  def initialize
    super.tap do
      @last_read_position = 0
    end
  end

  def start
    @should_run = true

    path = Hearthstone.log_path

    if path.file_exists?
      # if the file exists, we start reading at the end
      @last_read_position = file_size(path)
    end
    changes_in_file
  end

  def on_read_line(&block)
    @on_read_line = block.respond_to?('weak!') ? block.weak! : block
  end

  def stop
    @should_run = false
  end

  private
  def file_size(path)
    File.stat(path).size
  end

  # check each 0.5 sec if there are some modification in the log file
  def changes_in_file
    path = Hearthstone.log_path

    file_handle = NSFileHandle.fileHandleForReadingAtPath(path)
    file_handle.seekToFileOffset(@last_read_position)

    Dispatch::Queue.main.async do
      data                = file_handle.readDataToEndOfFile
      lines_str           = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      size                = @last_read_position
      @last_read_position = file_size(path)

      if @last_read_position > size

        lines = lines_str.split "\n"
        Dispatch::Queue.main.async do
          if lines.count > 0
            lines.each do |line|
              @on_read_line.call(line) if @on_read_line
            end
          end
        end
      end

      Dispatch::Queue.main.after(0.5) do
        if @should_run
          changes_in_file
        end
      end
    end
  end

end