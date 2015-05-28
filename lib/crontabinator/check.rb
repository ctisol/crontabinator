namespace :crontab do
  namespace :check do

    desc 'Ensure all crontabinator specific settings are set, and warn and exit if not.'
    before 'crontab:setup', :settings do
      {
        (File.dirname(__FILE__) + "/examples/config/deploy.rb") => 'config/deploy.rb',
        (File.dirname(__FILE__) + "/examples/config/deploy/staging.rb") => "config/deploy/#{fetch(:stage)}.rb"
      }.each do |abs, rel|
        Rake::Task['deployinator:settings'].invoke(abs, rel)
        Rake::Task['deployinator:settings'].reenable
      end
    end

    namespace :settings do
      desc 'Print example crontabinator specific settings for comparison.'
      task :print do
        set :print_all, true
        Rake::Task['crontab:check:settings'].invoke
      end
    end

  end
end
