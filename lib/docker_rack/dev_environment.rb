require 'net/http'

module Environment
  def self.work_dir
    @work_dir = @work_dir || ENV['WORK_DIR'] || Dir.pwd
  end

  # def self.docker_host
  #   host_ip = ENV['HOST_IP']
  #   return host_ip unless host_ip.nil?
  #   host_ip = ENV['DOCKER_HOST']
  #   return nil if host_ip.nil?
  #   host_ip[/tcp:\/\/([^:]+)/,1]
  # end
  #
  # def self.hostip
  #   @host_ip = @host_ip || docker_host || (`ifconfig docker0 | grep inet | grep 'inet\s' | awk '{print $2}'`).strip
  #   puts "#{@host_ip}."
  #   @host_ip
  # end

  def self.get_env(environment)
    env = environment || 'development'
    env.to_sym
  end

  def self.get_data(url)
    command = "curl #{url}"
    command += " 2> /dev/null" unless LOG_LEVEL == 'DEBUG'
    puts command if LOG_LEVEL == 'DEBUG'
    if Gem.win_platform?
      uri = URI(url)
      result = Net::HTTP.get(uri)
    else
      result = `#{command}`
    end
    puts result
    validate!
    puts "Result: #{result}" if LOG_LEVEL == 'DEBUG'
    return result
  end

  def self.post_data(url, payload)
    command = "curl -X PUT -d '#{payload}' #{url}"
    command += " 2> /dev/null" unless LOG_LEVEL == 'DEBUG'
    puts command if LOG_LEVEL == 'DEBUG'
    if Gem.win_platform?
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      # http.set_debug_output($stdout)
      header = {'Content-Type' => 'text/json'}
      request = Net::HTTP::Put.new(uri.request_uri, initheader = header)
      # request.add_field('Content-Type', 'application/json')
      # request.add_field('Content-Type', 'text/plain; charset=utf-8')
      request.body = payload # .to_json
      response = http.request(request)
      result = response.body
    else
      result = `#{command}`
    end
    validate!
    puts "Result: #{result}" if LOG_LEVEL == 'DEBUG'
    return result
  end

  def self.validate!
    if $?.to_i == 0
      puts 'OK' if LOG_LEVEL == 'DEBUG'
    else
      puts 'Failed' if LOG_LEVEL == 'DEBUG'
    end
  end

end
