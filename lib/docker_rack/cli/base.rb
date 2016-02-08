require 'thor'

LOG_LEVEL = ENV['LOG_LEVEL'] || 'INFO'

module DockerRack
  module CLI
    class Base < Thor
      map '-v' => :version

      class_option :container_templates, aliases: :p, banner: '<path>', type: :string, default: 'container_templates'

      desc 'version', 'Shows current version'
      # CLI command that returns the version of Docker Rack
      def version
        puts DockerRack::VERSION
      end

      desc 'list [all]', 'List tasks'
      def list(all = nil)
        ct = init_runner

        ct.tasks.map do |task|
          comment = task.comment
          next if all != 'all' && comment.nil?
          comment = (comment.nil?) ? '' : '# ' + comment
          printf("%-40s %-40s\n\r", task.name, comment)
        end
      end

      desc 'exec TASK_NAME', 'Run task by NAME'
      def exec(name)
        ct = init_runner

        unless ct.contains?(name)
          puts "Task with name '#{name}' doesn't exist."
          abort
        end

        puts "Executing '#{name}'"
        ct.invoke(name)
      end

      private

      def init_runner
        ct = Container::Templates::RakeTask.new
        ct.process(path: options[:container_templates])

        ct
      end
    end
  end
end
