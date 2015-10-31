namespace :crontab do
  namespace :check do

    task :scripts do
      files = Dir.glob("#{fetch(:crontab_scripts_path)}/*\.erb")
      set :crontab_script_files, files.collect { |f| File.expand_path(f) }
      fetch(:crontab_script_files).each do |file|
        hash = eval(File.read(file).lines.to_a.shift)
        if hash.nil? or hash[:user].nil? or hash[:schedule].nil?
          fatal "Error reading the first line of #{file}"
          fatal "Ensure the first line is a Ruby hash in the form: " +
            "\"{ :user => \"www-data\", :schedule => \"* * * * *\" }\""
          fatal "Your shebang line directly next"
        end
      end
    end

    desc 'Ensure all crontabinator specific settings are set, and warn and exit if not.'
    task :settings => [:scripts] do
      {
        (File.dirname(__FILE__) + "/examples/config/deploy.rb") => 'config/deploy.rb',
        (File.dirname(__FILE__) + "/examples/config/deploy/staging.rb") => "config/deploy/#{fetch(:stage)}.rb"
      }.each do |abs, rel|
        Rake::Task['deployinator:settings'].invoke(abs, rel)
        Rake::Task['deployinator:settings'].reenable
      end
    end
    before 'crontab:setup', 'crontab:check:settings'

    namespace :settings do
      desc 'Print example crontabinator specific settings for comparison.'
      task :print do
        set :print_all, true
        Rake::Task['crontab:check:settings'].invoke
      end
    end

  end
end
