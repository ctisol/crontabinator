##### crontabinator
### ------------------------------------------------------------------
set :domain,                        "my-app.example.com"
server fetch(:domain),
  :user                             => fetch(:deployment_username),
  :roles                            => ["cron"]
set :user_crontab_entries,          {
  "www-data"                          => [
    "SHELL=/bin/bash",
    "MAILTO=myemail@example.com",
    "0 */4 * * * #{current_path}/script/myscript > /dev/null"
  ],
  "root"                              => [
    "SHELL=/bin/bash",
    "MAILTO=myemail@example.com",
    "0 */4 * * * /usr/local/bin/myscript > /dev/null"
  ]
}
### ------------------------------------------------------------------
