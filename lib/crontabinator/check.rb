namespace :crontab do
  namespace :check do

    task :scripts => 'deployinator:load_settings' do
      run_locally do
        files = Dir.glob("#{fetch(:crontab_scripts_path)}/*\.erb")
        set :crontab_script_files, files.collect { |f| File.expand_path(f) }
        fetch(:crontab_script_files).each do |file|
          hash = eval(File.read(file).lines.to_a.shift).deep_symbolize_keys
          if hash.nil? or hash[:user].nil? or hash[:schedule].nil? or hash[:stages].nil?
            fatal "Error reading the first line of #{file}"
            fatal "Ensure the first line is a Ruby hash in the form: " +
              "\"{ :user => \"www-data\", :schedule => \"* * * * *\", :stages => [:production, :staging] }\""
            fatal "Your shebang line directly next"
            exit
          end
        end
      end
    end

    task :erb_validity => 'deployinator:load_settings' do
      run_locally do
        fetch(:crontab_script_files).each do |file|
          unless test "erb", "-x", "-T", "'-'", file, "|", "ruby", "-c"
            fatal "There's a syntax error with #{file}"
            fatal "Test it manually with `erb -x -T '-' #{file} | ruby -c`"
            exit
          end
        end
      end
    end

    desc 'Ensure all crontabinator specific settings are set, and warn and exit if not.'
    task :settings => [:scripts, :erb_validity] do
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
      task :print => 'deployinator:load_settings' do
        set :print_all, true
        Rake::Task['crontab:check:settings'].invoke
      end
    end

  end
end

class Object
  def deep_symbolize_keys
    return self.inject({}){|memo,(k,v)| memo[k.to_sym] = v.deep_symbolize_keys; memo} if self.is_a? Hash
    return self.inject([]){|memo,v    | memo           << v.deep_symbolize_keys; memo} if self.is_a? Array
    return self
  end
end
