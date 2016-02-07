require 'docker_rack/version'

require 'docker_rack/docker_utils'
require 'docker_rack/container_template'
# require 'docker_rack/task_mngr'

module DockerRack
  class << self
    attr_reader :client, :debug, :no_debug
    attr_writer :logger

    def debug!
      @debug = true
      logger.level = Logger::DEBUG
    end

    def no_debug!
      @debug = false
      logger.level = Logger::INFO
    end

    def logger
      @logger ||= client ? client.logger : Logger.new(STDOUT)
    end
  end
end

require 'docker_rack/cli/base'
