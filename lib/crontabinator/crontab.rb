namespace :crontab do

  desc "Idempotently setup Crontabs."
  task :setup do
    log_level = SSHKit.config.output_verbosity
    log_level = "info" if log_level.nil?
    SSHKit.config.output_verbosity = fetch(:crontab_log_level)

    on roles(:cron) do |host|
      fetch(:user_crontab_entries).each do |user, entries|
        unless unix_user_exists?(user)
          error "User #{user} does not exist even though you defined crontab settings for it - Skipping!"
        else
          set :crontab_entries, entries
          template_path = File.expand_path("./#{fetch(:crontab_templates_path)}/crontab.erb")
          generated_config_file = ERB.new(File.new(template_path).read, nil, '-').result(binding)
          upload! StringIO.new(generated_config_file), "/tmp/crontab"
          as :root do
            execute("chown", "#{user}:#{user}", "/tmp/crontab")
          end
          as user do
            execute "crontab", "/tmp/crontab"
          end
          as :root do
            execute "rm", "/tmp/crontab"
          end
        end
      end
    end
    SSHKit.config.output_verbosity = log_level
  end

  if Rake::Task.task_defined?("deploy:publishing")
    after 'deploy:publishing', 'crontab:setup'
  end

  desc "Check the status of the Crontabs."
  task :status do
    log_level = SSHKit.config.output_verbosity
    log_level = "info" if log_level.nil?
    SSHKit.config.output_verbosity = fetch(:crontab_log_level)

    on roles(:cron) do
      fetch(:user_crontab_entries).each do |user, _|
        as :root do
          unless unix_user_exists?(user)
            error "User #{user} does not exist even though you defined crontab settings for it - Skipping!"
          else
            info "Crontab for user #{user}:\n#{capture "crontab", "-u", user, "-l" if test "crontab", "-u", user, "-l"}"
          end
        end
      end
    end

    SSHKit.config.output_verbosity = log_level
  end

end
