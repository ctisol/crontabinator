# config valid only for Capistrano 3.2.1
lock '3.2.1'

##### crontabinator
### ------------------------------------------------------------------
#set :application,                   "my_app_name"
set :deployment_username,           ENV['USER']
### ------------------------------------------------------------------
