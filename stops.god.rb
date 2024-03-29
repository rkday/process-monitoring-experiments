require_relative './flapping2.rb'

God.watch do |w|
  w.name = "stops"
  w.interval = 5.seconds
  w.start = "ruby /home/rkd/critters/stops.rb"

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 150.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.action = lambda {puts "I AM FLAPPING!"}
      c.between_actions = 3600.seconds
    end
  end
end
