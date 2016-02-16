# rubocop:disable Metrics/AbcSize

module Docker
  class Utils

    def self.dockerhost
      @dockerhost = ENV['DOCKER_HOST']
      return nil if @dockerhost.nil?
      @dockerhost[/tcp:\/\/([^:]+)/, 1]
    end

    def self.create_docker_command(info)
      docker_cmd = ['docker']
      docker_cmd.push info['action'] || 'run -d'
      docker_cmd.push "--name=\"#{info['name']}\""
      docker_cmd.push "--add-host=\"dockerhost:#{dockerhost}\"" unless info.key? 'net'
      docker_cmd.push "--hostname=\"#{info['hostname']}\"" if info.key? 'hostname'
      docker_cmd.push info['environment'].map { |k, v| "-e #{k.to_s}=\"#{v}\"" } if info.key? 'environment'
      docker_cmd.push info['ports'].map { |port| "-p #{mirror_if_single(port)}" } if info.key? 'ports'
      docker_cmd.push info['expose'].map { |port| "--expose=#{port}" } if info.key? 'expose'
      docker_cmd.push info['links'].map { |link| "--link #{link}" } if info.key? 'links'
      docker_cmd.push info['volumes_from'].map { |volume| "--volumes-from \"#{volume}\"" } if info.key? 'volumes_from'
      docker_cmd.push info['volumes'].map { |volume| "-v #{quote_parts(volume)}" } if info.key? 'volumes'
      docker_cmd.push "--net=\"#{info['net']}\"" if info.key? 'net'
      docker_cmd.push '--privileged' if info['privileged'] == true
      docker_cmd.push "--pid=\"#{info['pid']}\"" if info.key? 'pid'
      docker_cmd.push "--log-driver=\"#{info['log-driver']}\"" if info.key? 'log-driver'
      docker_cmd.push info['log-opt'].map { |k, v| "--log-opt #{k.to_s}=\"#{v}\"" } if info.key? 'log-opt'
      docker_cmd.push info['image']
      docker_cmd.push info['command'] if info.key? 'command'
      return docker_cmd.join(' ')
    end

    def self.quote_parts(text)
      text.split(':').map { |s| "\"#{s}\""}.join(':')
    end

    def self.mirror_if_single(text)
      parts = text.to_s.split(':')
      parts.count == 1 ? "#{text}:#{text}" : text
    end

    def self.stop_container(container_template)

      name = container_template['name']
      # containers = `docker ps`
      ps = containers_by_name(name)
      ps.each do |line|
        if line != ''
          cmd = "docker inspect -f {{.State.Running}} #{line}"
          puts cmd if LOG_LEVEL == 'DEBUG'
          is_running = `#{cmd}`.strip
          if is_running == 'true'
            cmd = "docker kill #{line}"
            puts cmd if LOG_LEVEL == 'DEBUG'
            `#{cmd}`
          else
            puts 'Container not running. Nothing to kill. Skipping...'
          end
        end
      end

      ps = containers_by_name(name)
      ps.each do |line|
        if line != ''
          cmd = "docker rm #{line}"
          puts cmd if LOG_LEVEL == 'DEBUG'
          `#{cmd}`
        end
      end
    end

    def self.start_container(info)
      command = create_docker_command(info)
      puts command if LOG_LEVEL == 'DEBUG'
      if present?(info['name'])
        skip_first_sleep = true
        puts 'Detected as running. Skipping ....' # if LOG_LEVEL == 'DEBUG'
      else
        `#{command}`
      end
      Array(info['checks']).each do |check|
        try = (check['retry'] || 3).to_i
        interval = (check['interval'] || 2).to_i
        check['ip'] ||= dockerhost
        detect_check(check)
        while true
          sleep interval unless skip_first_sleep
          skip_first_sleep = false
          put_char '.' if LOG_LEVEL != 'DEBUG'
          case check['type']
            when 'port'
              break if check_port(check)
            when 'rest'
              break if check_rest(check)
            when 'script'
              break if check_script(check)
            else
              puts 'Unrecognizable check type. Skipping ...'
          end
          try -= 1
          abort '  Health check failed all retries' if try == 0
        end
        puts
      end
    end

    def self.detect_check(check)
      return if check.key?('type')
      if check.key?('port')
        check['type'] = 'port'
      elsif check.key?('uri')
        check['type'] = 'rest'
      end
    end

    def self.check_port(check)
      puts "Checking port #{check['ip']}:#{check['port']} availability." if LOG_LEVEL == 'DEBUG'
      result = is_port_open?(check['ip'], check['port'])
      puts "Result: #{result}" if LOG_LEVEL == 'DEBUG'
      return result
    end

    def self.check_rest(check)
      puts "Checking HTTP response #{check['uri']}." if LOG_LEVEL == 'DEBUG'
      result = is_http_present?(check['uri'])
      puts "Result: #{result}" if LOG_LEVEL == 'DEBUG'
      return result
    end

    def self.check_script(check)
      `#{check['script']}`
      return $?.to_i == 0
    end

    def self.put_char(str)
      print str
      $stdout.flush
    end

    def self.is_http_present?(url)
      begin
        uri = URI(url)
        request = Net::HTTP::Get.new(uri.request_uri)
        response = Net::HTTP.start(uri.host, uri.port, :read_timeout => 500) {|http| http.request(request)}

        return response.code == '200'
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        # ignored
      end
      return false
    end

    def self.is_port_open?(ip, port)
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
        # ignored
      end

      return false
    end

    def self.present?(name)
      !containers_by_name(name).empty?
    end

    def self.containers_by_name(name)
      containers = `docker ps -a`
      ps = []
      containers.each_line { |line| if line.include?(name) then ps << line.strip.partition(' ').first end }
      ps
    end

    def self.get_image_id(name)
      images = `docker images`
      img = []
      images.each_line { |line| if line.include?(name) then img << line.strip.partition(' ').first end }
      img.first
    end

  end
end
