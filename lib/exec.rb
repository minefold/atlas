class ProcessTimeout < StandardError; end

class Exec
  # Runs a process. Raises error on non zero exit
  # options:
  #   output_timeout: Kills process if it doesn't write to stdout after given timeout in seconds
  def self.run(cmd, options = {}, &blk)
    result = ''
    IO.popen(cmd) do |io|
      begin
        while line = gets_timeout(io, options[:output_timeout]) do
          puts line
          result << line
          yield io.pid, line if block_given?
        end
      rescue Timeout::Error
        Process.kill('TERM', io.pid)
        raise ProcessTimeout
      end
    end
    raise result unless $?.exitstatus == 0
    result
  end

  def self.gets_timeout(io, timeout)
    if timeout
      Timeout::timeout(timeout) { io.gets }
    else
      io.gets
    end
  end
end