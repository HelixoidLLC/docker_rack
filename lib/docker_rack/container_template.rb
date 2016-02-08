require 'rake'
require 'rake/tasklib'
require 'pathname'
require 'erb'
require 'ostruct'
require 'yaml'
require 'json/ext'
require 'net/http'

require_relative 'docker_utils'
require_relative 'dev_environment'
require_relative 'utils'

module Container
  module Templates

    class RakeTask # < ::Rake::TaskLib
      # include Rake::TaskManager
      include ::Rake::DSL if defined?(::Rake::DSL)

      # Default pattern for template files.
      # DEFAULT_PATTERN        = 'container_templates/**{,/*/**}/*.{yml,yaml}'
      DEFAULT_PATTERN = '**/*.{yml,yaml}'

      DEFAULT_PATH = 'container_templates'

      # Name of task. Defaults to `:container_templates`.
      attr_accessor :name

      # Path to Container templates. Defaults to the absolute path to the
      # relative location of container templates.
      attr_accessor :templates_path

      # Files matching this pattern will be loaded.
      # Defaults to `'**/*.{yml,yaml}'`.
      attr_accessor :pattern

      def initialize
        options = Rake.application.options
        options.trace = false
        options.dryrun = false

        Rake::TaskManager.record_task_metadata = true

        $environment = environment
      end

      def process(params)
        @templates_path = params[:path] || DEFAULT_PATH
        @pattern        = params[:pattern] || DEFAULT_PATTERN

        load_templates @templates_path, @pattern

        scripts_path = File.join(@templates_path, 'scripts/*.rake')
        puts "Loading scripts from '#{scripts_path}'" if LOG_LEVEL == 'DEBUG'

        Dir.glob(scripts_path).each do |r|
          load r
        end
      end

      def tasks
        Rake.application.tasks()
      end

      def contains?(task_name)
        tasks.any? { |task| task.name == task_name }
      end

      def invoke(name)
        Rake.application[name].invoke
      end

      def environment
        {
            dockerhost: Docker::Utils.dockerhost,
            work_dir: Environment.work_dir
        }
      end

      private

      def load_templates(path, pattern)
        # curr = Pathname.new(Dir.pwd) + path
        # puts "Current: #{curr}"

        FileList[File.join(path, pattern)].each do |f|
          load_template_from_file File.expand_path(f)
        end
      end

      def strip_extension(filename)
        filename.gsub(/(\.yml|\.yaml|\.erb)/, '')
      end

      def friendly_name(filename)
        filename.gsub(/[^\w\s_-]+/, '_')
            .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
            .gsub(/\s+/, '_')
      end

      def load_template_from_file(path)
        load_container_template(path).each do |_, container_template|
          define_start_task container_template, path
          define_stop_task container_template, path
          define_restart_task container_template, path
          define_help_task container_template, path
        end
      end

      def define_start_task(container_template, path)
        container_name = "container:#{container_template['name']}:start"
        dependencies = container_template['depends']

        args = []
        if dependencies.nil?
          args.insert 0, container_name
        else
          args.insert 0, container_name => dependencies.map { |id| "container:#{id}:start" }
        end

        body = proc do
          puts "Starting: #{path}"
          Docker::Utils.start_container container_template
        end

        Rake::Task.define_task(*args, &body)
      end

      def define_stop_task(container_template, path)
        container_name = "container:#{container_template['name']}:stop"
        dependencies = container_template['depends'] || []

        args = []
        args.insert 0, container_name

        body = proc do
          puts "Stopping: #{path}"
          Docker::Utils.stop_container container_template
        end

        Rake::Task.define_task(*args, &body)

        # Create reverse dependency
        dependencies.map { |id| "container:#{id}:stop" }.each do |id|
          task id => container_name
        end
      end

      def define_restart_task(container_template, path)
        container_name = "container:#{container_template['name']}"
        task (container_name + ':restart').to_sym do
          puts "Restarting: #{path}"
          Rake::Task[container_name + ':stop'].invoke
          Rake::Task[container_name + ':start'].invoke
        end
      end

      def define_help_task(container_template, path)
        container_name = "container:#{container_template['name']}"
        desc "Tasks help for #{container_name}"
        task (container_name + ':help').to_sym do
          puts "Tasks for: #{path}"
          printf("%-40s %-40s\n\r", "#{container_name}:start", "# Starting   #{container_name}")
          printf("%-40s %-40s\n\r", "#{container_name}:stop", "# Stopping   #{container_name}")
          printf("%-40s %-40s\n\r", "#{container_name}:restart", "# Restarting #{container_name}")
        end
      end

      def load_template_file(file_path)
        puts "Loading #{file_path}" if LOG_LEVEL == 'DEBUG'

        vars = environment

        container_template = YAML.load_file(file_path)
        if Pathname.new(file_path).basename.to_s.include? '.erb'
          template = ERB.new(container_template.to_yaml).result(OpenStruct.new(vars).instance_eval { binding })
          container_template = YAML.load(template)
        end

        puts container_template.to_yaml if LOG_LEVEL == 'DEBUG'

        return container_template
      end

      def load_container_template(file_path)
        container_template = load_template_file(file_path)

        container_template.each do |template_id, template|
          template['name'] = template_id
          next unless template.key? 'environment'
          environment                 = template['environment']
          # TODO: simplify this
          environment['LOG_LEVEL']    = LOG_LEVEL unless environment.key? 'LOG_LEVEL'
        end
      end
    end

  end
end
