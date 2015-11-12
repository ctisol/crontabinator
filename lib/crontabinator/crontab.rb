namespace :crontab do

  # sets :user_crontab_hash in the form:
  # { :"username" => ["#!/bin/bash", "/bin/echo 'asdf' >> /tmp/test.log"] }
  task :read_all_settings => ['crontab:check:scripts'] do
    run_locally do
      user_crontab_hash = {}

      # Auto entries
      auto_entries = []
      fetch(:crontab_script_files).each do |file|
        hash = eval(File.read(file).lines.to_a.shift).deep_symbolize_keys
        hash[:stages] = hash[:stages].collect { |stage| stage.to_sym }
        if hash[:stages].include? fetch(:stage)
          path = "#{fetch(:crontab_server_scripts_path)}/#{File.basename(file, '.erb')}"
          auto_entries += [{ :user => hash[:user], :schedule => hash[:schedule], :path => path }]
        end
      end
      auto_entries.each do |entry|
        name = File.basename(entry[:path], '.erb')
        user_crontab_hash[entry[:user]] ||= []
        user_crontab_hash[entry[:user]] << [
          "# #{name}",
          "#{entry[:schedule]} #{entry[:path]} >> #{fetch(:crontab_logs_path)}/#{name}.log 2>&1",
          ""
        ]
      end

      # User entries
      fetch(:user_crontab_entries, {}).each do |user, lines|
        user_crontab_hash[user] ||= []
        user_crontab_hash[user] << [lines]
      end

      # All entries
      user_crontab_hash.each { |user, lines| user_crontab_hash[user] = lines.flatten }

      set :user_crontab_hash, user_crontab_hash

      # Newly removed crontabs
      crontabs_to_remove = []
      if File.exists?(fetch(:crontab_lockfile_path))
        old_users = eval(File.read(fetch(:crontab_lockfile_path))).sort
        new_users = user_crontab_hash.collect { |user, _| user }.sort
        crontabs_to_remove = old_users - new_users
      end
      set :crontabs_to_remove, crontabs_to_remove
    end
  end

  task :upload_scripts => [:read_all_settings] do
    on roles(:cron) do |host|
      fetch(:crontab_script_files).each do |path|
        lines = File.read(path).lines.to_a
        hash = eval(lines.shift).deep_symbolize_keys
        hash[:stages] = hash[:stages].collect { |stage| stage.to_sym }
        if hash[:stages].include? fetch(:stage).to_sym
          file = ERB.new(lines.join, nil, '-').result(binding)
          as :root do execute("rm", "/tmp/script", "-f") end
          upload! StringIO.new(file), "/tmp/script"
          final_path = "#{fetch(:crontab_server_scripts_path)}/#{File.basename(path, '.erb')}"
          as :root do
            execute("mv", "/tmp/script", final_path)
            execute("chmod", "750", final_path)
          end
        end
      end
    end
  end

  desc "Idempotently setup Crontabs."
  task :setup => ['crontab:check:settings', :read_all_settings, :upload_scripts] do
    on roles(:cron) do |host|
      # New
      fetch(:user_crontab_hash).each do |user, lines|
        unless unix_user_exists?(user)
          error "You defined crontab settings for '#{user}', but no such user exists - Skipping!"
        else
          set :crontab_entries, lines
          path = File.expand_path("./#{fetch(:crontab_templates_path)}/crontab.erb")
          file = ERB.new(File.read(path), nil, '-').result(binding)
          as :root do execute("rm", "/tmp/crontab", "-f") end
          upload! StringIO.new(file), "/tmp/crontab"
          as :root do execute("chown", "#{user}:#{user}", "/tmp/crontab") end
          as user do execute "crontab", "/tmp/crontab" end
          as :root do
            execute "rm", "/tmp/crontab"
          end
        end
      end

      # Old
      fetch(:crontabs_to_remove).each do |user|
        as :root do
          test "crontab", "-u", user, "-r"
        end
      end
      content = [
        "# Add this file to version control, - it tracks and removes crontab",
        "#   entries on the server which you have removed from the config",
        fetch(:user_crontab_hash).collect { |u, _| u }.sort.to_s
      ].join("\n") + "\n"
      unless File.exists?(fetch(:crontab_lockfile_path)) &&
          File.read(fetch(:crontab_lockfile_path)) == content
        File.open(fetch(:crontab_lockfile_path), 'w') { |f| f.write(content) }
        warn "Updated '#{fetch(:crontab_lockfile_path)}', add it to version control"
      end
    end
  end

  if Rake::Task.task_defined?("deploy:publishing")
    after 'deploy:publishing', 'crontab:setup'
  end

  desc "Check the status of the Crontabs."
  task :status => [:read_all_settings] do
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
  end

end
