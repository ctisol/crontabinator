namespace :crontab do

  # sets :user_crontab_hash in the form:
  # { :"user" => ["#!/bin/bash", "/bin/echo 'asdf' >> /tmp/test.log"] }
  task :read_all_settings => ['crontab:check:scripts'] do
    run_locally do
      user_crontab_hash = {}

      # Auto entries
      auto_entries = []
      fetch(:crontab_script_files).each do |file|
        hash = eval(File.read(file).lines.to_a.shift)
        path = "#{fetch(:crontab_server_scripts_path)}/#{File.basename(file, '.erb')}"
        auto_entries += [{ :user => hash[:user], :schedule => hash[:schedule], :path => path }]
      end
      auto_entries.each do |entry|
        name = File.basename(entry[:path], '.erb')
        user_crontab_hash[entry[:user]] ||= []
        user_crontab_hash[entry[:user]] << [
          "# #{name}",
          "#{entry[:schedule]} #{entry[:path]} >> #{fetch(:crontab_logs_path)}/#{name} 2>&1",
          ""
        ]
      end

      # User entries
      fetch(:user_crontab_entries).each do |user, lines|
        user_crontab_hash[user] ||= []
        user_crontab_hash[user] << [lines]
      end

      # All entries
      user_crontab_hash.each do |user, lines|
        # Cron needs an extra return at the EOF, don't remove this
        lines += ["\n"]
        user_crontab_hash[user] = lines.flatten
      end

      set :user_crontab_hash, user_crontab_hash
    end
  end

  task :upload_scripts => [:read_all_settings] do
    on roles(:cron) do |host|
      fetch(:crontab_script_files).each do |path|
        lines = File.read(path).lines.to_a
        lines.shift
        file = ERB.new(lines.join, nil, '-').result(binding)
        upload! StringIO.new(file), "/tmp/script"
        final_path = "#{fetch(:crontab_server_scripts_path)}/#{File.basename(path, '.erb')}"
        as :root do
          warn "final path is " + final_path
          execute("mv", "/tmp/script", final_path)
          execute("chmod", "750", final_path)
        end
      end
    end
  end

  desc "Idempotently setup Crontabs."
  task :setup => [:read_all_settings, :upload_scripts] do
    log_level = SSHKit.config.output_verbosity
    log_level = "info" if log_level.nil?
    SSHKit.config.output_verbosity = fetch(:crontab_log_level)

    on roles(:cron) do |host|
      fetch(:user_crontab_hash).each do |user, lines|
        unless unix_user_exists?(user)
          error "You defined crontab settings for '#{user}', but no such user exists - Skipping!"
        else
          set :crontab_entries, lines
          path = File.expand_path("./#{fetch(:crontab_templates_path)}/crontab.erb")
          file = ERB.new(File.read(path), nil, '-').result(binding)
          upload! StringIO.new(file), "/tmp/crontab"
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
  task :status => [:read_all_settings] do
    log_level = SSHKit.config.output_verbosity
    log_level = "info" if log_level.nil?
    SSHKit.config.output_verbosity = fetch(:crontab_log_level)

    on roles(:cron) do
      fetch(:user_crontab_hash).each do |user, _|
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
