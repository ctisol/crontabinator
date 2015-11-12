crontabinator
============

*Repeatably install crontabs*

This is a Capistrano 3.x plugin, and relies on SSH access with passwordless sudo rights.

### Installation:
* `gem install crontabinator` (Or add it to your Gemfile and `bundle install`.)
* Add "require 'crontabinator'" to your Capfile
`echo "require 'crontabinator'" >> Capfile`
* Create example configs:
`cap crontabinator:write_example_configs`
* Turn them into real configs by removing the `_example` portions of their names, and adjusting their content to fit your needs. (Later when you upgrade to a newer version of crontabinator, you can `crontabinator:write_example_configs` again and diff your current configs against the new configs to see what you need to add.)
* Add the role `:cron` to whatever servers you would like to have crons installed upon.
* Ensure the `scripts.d/` directory's files get set executable (E.G. using `deployinator`'s `:webserver_executeable_dirs`)

### Usage:
`cap -T` will help remind you of the available commands, see this for more details.
* After setting up your config files during installation, simply run:
`cap <stage> crontab:setup`
* Run `cap <stage> crontab:status` to see the status of the crontabs.

###### Debugging:
* You can add the `--trace` option at the end of a command to see when which tasks are invoked, and when which task is actually executed.

###### TODO:
