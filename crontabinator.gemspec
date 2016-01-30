Gem::Specification.new do |s|
  s.name        = 'crontabinator'
  s.version     = '0.0.4'
  s.date        = '2015-11-11'
  s.summary     = "Deploy Crontabs"
  s.description = "Deploy Crontabs using an existing Cron Daemon"
  s.authors     = ["david amick"]
  s.email       = "davidamick@ctisolutionsinc.com"
  s.files       = [
    "lib/crontabinator.rb",
    "lib/crontabinator/crontab.rb",
    "lib/crontabinator/config.rb",
    "lib/crontabinator/check.rb",
    "lib/crontabinator/built-in.rb",
    "lib/crontabinator/examples/Capfile",
    "lib/crontabinator/examples/config/deploy.rb",
    "lib/crontabinator/examples/config/deploy/staging.rb",
    "lib/crontabinator/examples/crontab.erb",
    "lib/crontabinator/examples/myscript.sh.erb"
  ]
  s.required_ruby_version  =                '>= 1.9.3'
  s.requirements           <<               "Cron Daemon"
  s.add_runtime_dependency 'capistrano',    '~> 3.2.1'
  s.add_runtime_dependency 'deployinator',  '~> 0.2.0'
  s.add_runtime_dependency 'rake',          '~> 10.3.2'
  s.add_runtime_dependency 'sshkit',        '~> 1.5.1'
  s.homepage    =
    'https://github.com/snarlysodboxer/crontabinator'
  s.license     = 'GNU'
end
