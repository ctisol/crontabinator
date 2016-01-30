module Capistrano
  module TaskEnhancements
    alias_method :crontab_original_default_tasks, :default_tasks
    def default_tasks
      crontab_original_default_tasks + [
        "crontabinator:write_built_in",
        "crontabinator:write_example_configs",
        "crontabinator:write_example_configs:in_place"
      ]
    end
  end
end

namespace :crontabinator do

  set :example, "_example"

  desc "Write example config files (with '_example' appended to their names)."
  task :write_example_configs => 'deployinator:load_settings' do
    run_locally do
      execute "mkdir", "-p", "config/deploy", fetch(:crontab_templates_path), fetch(:crontab_scripts_path)
      {
        "examples/Capfile"                    => "Capfile#{fetch(:example)}",
        "examples/config/deploy.rb"           => "config/deploy#{fetch(:example)}.rb",
        "examples/config/deploy/staging.rb"   => "config/deploy/staging#{fetch(:example)}.rb",
        "examples/crontab.erb"                => "#{fetch(:crontab_templates_path)}/crontab#{fetch(:example)}.erb",
        "examples/myscript.sh.erb"            => "#{fetch(:crontab_scripts_path)}/myscript#{fetch(:example)}.sh.erb"
      }.each do |source, destination|
        config = File.read(File.dirname(__FILE__) + "/#{source}")
        File.open("./#{destination}", 'w') { |f| f.write(config) }
        info "Wrote '#{destination}'"
      end
      unless fetch(:example).empty?
        info "Now remove the '#{fetch(:example)}' portion of their names or diff with existing files and add the needed lines."
      end
    end
  end

  desc 'Write example config files (will overwrite any existing config files).'
  namespace :write_example_configs do
    task :in_place => 'deployinator:load_settings' do
      set :example, ""
      Rake::Task['crontabinator:write_example_configs'].invoke
    end
  end

  desc 'Write a file showing the built-in overridable settings.'
  task :write_built_in => 'deployinator:load_settings' do
    run_locally do
      {
        'built-in.rb'                         => 'built-in.rb',
      }.each do |source, destination|
        config = File.read(File.dirname(__FILE__) + "/#{source}")
        File.open("./#{destination}", 'w') { |f| f.write(config) }
        info "Wrote '#{destination}'"
      end
      info "Now examine the file and copy-paste into your deploy.rb or <stage>.rb and customize."
    end
  end

end
