require 'yaml'

begin
  load 'local.rake'
rescue LoadError
  # nothing
end

$EDEM_ENV = ENV.fetch('EDEM_ENV', 'local')

ssh_config_file = "config/#{$EDEM_ENV}/ssh_config"
ips_file = "config/#{$EDEM_ENV}/ips.yaml"
config_file = "config/#{$EDEM_ENV}/config.yaml"

ENV['CHAKE_TMPDIR'] = "tmp/chake.#{$EDEM_ENV}"
ENV['CHAKE_SSH_CONFIG'] = ssh_config_file

chake_rsync_options = ENV['CHAKE_RSYNC_OPTIONS'].to_s.clone
chake_rsync_options += ' --exclude backups'
chake_rsync_options += ' --exclude src'
ENV['CHAKE_RSYNC_OPTIONS'] = chake_rsync_options

require 'chake'

if Gem::Version.new(Chake::VERSION) < Gem::Version.new('0.13')
  fail "Please upgrade to chake 0.10+"
end

ips ||= YAML.load_file(ips_file)
config ||= YAML.load_file(config_file)
$nodes.each do |node|
  node.data['environment'] = $EDEM_ENV
  node.data['config'] = config
  node.data['peers'] = ips
end

file 'ssh_config.erb'
if ['local', 'lxc'].include?($EDEM_ENV)
  file ssh_config_file => ['nodes.yaml', ips_file, 'ssh_config.erb', 'Rakefile'] do |t|
    require 'erb'
    template = ERB.new(File.read('ssh_config.erb'))
    File.open(t.name, 'w') do |f|
      f.write(template.result(binding))
    end
    puts 'ERB %s' % t.name
  end
end

desc "Install bootstrap dependencies"
task :install_deps => ssh_config_file do
  sh 'ssh', '-F', ssh_config_file, 'edemocracia', 'sudo', 'yum install -y wget rsync'
end

task 'bootstrap_common' => ssh_config_file
task 'run_input' => ssh_config_file

Dir.glob('tasks/*.rake').each { |f| load f }