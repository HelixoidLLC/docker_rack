require 'rspec/core/rake_task'
require 'yard'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new

YARD::Config.load_plugin 'thor'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', 'lib/**/**/*.rb']
end

namespace :doc do
  # This task requires that graphviz is installed locally. For more info:
  # http://www.graphviz.org/
  desc 'Generates the class diagram using the yard generated dot file'
  task :generate_class_diagram do
    puts 'Generating the dot file...'
    `yard graph --file jenkins_api_client.dot`
    puts 'Generating class diagram from the dot file...'
    `dot jenkins_api_client.dot -Tpng -o jenkins_api_client_class_diagram.png`
  end
end

task default: [:spec, :rubocop]
