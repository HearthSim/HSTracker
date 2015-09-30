class LogReaderManager

  TimeoutRead = 0.5

  def self.start
    init_readers

    @starting_point = get_starting_point
    @read_thread = NSThread.alloc.initWithTarget(self, selector: :start_log_readers, object:nil)
    @read_thread.start
  end

  def self.init_readers
    @power = LogReader.new('Power',
      starts_filters: ['GameState.'],
      contains_filters: [ "Begin Spectating", "Start Spectator", "End Spectator" ])
    @bob = LogReader.new('Bob')

    @readers = [@power, @bob]
    %w(Rachelle Asset Arena).each do |name|
      @readers << LogReader.new(name)
    end

    @readers << LogReader.new('Zone', contains_filters: [ "zone from" ])
  end

  def self.get_starting_point
    power_entry = @power.find_entry_point("GameState.DebugPrintPower() - CREATE_GAME")
    bob_entry = @bob.find_entry_point("legend rank")
    mp power_entry: power_entry,
      bob_entry: bob_entry,
      diff: power_entry > bob_entry
    power_entry > bob_entry ? power_entry : bob_entry
  end

  def self.start_log_readers
    return if @running

    mp starting_readers: @starting_point
    @readers.each do |reader|
      reader.start(@starting_point)
    end

    @running = true
    @stop = false
    @to_process = {}

    until @stop do
      @readers.each do |reader|
        lines = reader.collect
        lines.each do |line|
          unless @to_process.has_key?(line.time)
            @to_process[line.time] = []
          end
          @to_process[line.time] << line
        end
      end
      Dispatch::Queue.main.async do
        process_new_lines
      end
      NSThread.sleepForTimeInterval(TimeoutRead)
    end
    @running = false
  end

  def self.stop
    return unless @running

    @stop = true

    while @running do
      NSThread.sleepForTimeInterval(0.5)
    end
  end

  def self.restart
    return unless @running

    stop
    @starting_point = get_starting_point

    Dispatch::Queue.concurrent.async do
      start_log_readers
    end
  end

  def self.process_new_lines
    @to_process.each do |time, lines|
      next if lines.nil? || lines.empty?

      lines.each do |line|
        next if line.nil?

        case line.namespace
        when 'Power'
          PowerGameStateHandler.handle(line.line)
        when 'Zone'
          ZoneHandler.handle(line.line)
        when 'Asset'
          AssetHandler.handle(line.line)
        when 'Bob'
          BobHandler.handle(line.line)
        when 'Rachelle'
          RachelleHandler.handle(line.line)
        when 'Arena'
          ArenaHandler.handle(line.line)
        end
      end
    end

    @to_process = {}
    #Helper.UpdateEverything(_game);
  end

end
