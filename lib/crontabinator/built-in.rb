set :crontab_logs_path,             -> { shared_path.join('log') }
set :crontab_templates_path,        "templates/crontab"
set :crontab_lockfile_path,         -> { "#{fetch(:crontab_templates_path)}/crontab.lock" }
set :crontab_scripts_path,          -> { "#{fetch(:crontab_templates_path)}/scripts.d" }
set :crontab_server_scripts_path,   -> { current_path.join('script') }
