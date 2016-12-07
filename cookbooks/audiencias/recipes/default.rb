dependencies = ['epel-release', 'git', 'python34', 'python-pip', 'python34-devel',
                'openssl-devel', 'redis', 'nodejs', 'npm']

dependencies.each do |package_name|
  package "#{package_name}"
end

user 'audiencias' do
  home "/home/#{node['config']['system']['user']}/"
  shell '/bin/bash'
end

group 'audiencias' do
  action :create
  members ['audiencias', node['config']['system']['user']]
end

execute 'install:bower' do
  command 'npm install -g bower'
  action :run
end

directory "#{node['config']['audiencias']['dir']}" do
  owner "#{node['config']['system']['user']}"
  group "audiencias"
  mode '0755'
  action :create
  recursive true
end


git "#{node['config']['audiencias']['dir']}" do
  repository node['config']['audiencias']['repository']
  revision node['config']['audiencias']['branch']
  user "#{node['config']['system']['user']}"
  group "audiencias"
  action :sync
end

directory "#{node['config']['audiencias']['dir']}/public" do
  owner "#{node['config']['system']['user']}"
  group "audiencias"
  mode '0755'
  action :create
end

directory "#{node['config']['audiencias']['dir']}/static/bower_components" do
  owner "#{node['config']['system']['user']}"
  group "audiencias"
  mode '0755'
  action :create
end

execute "virtualenv" do
  command "pip install -U virtualenv"
end

execute "virtualenv #{node['config']['audiencias']['virtualenv']} -p python3" do
  not_if do FileTest.directory?(node['config']['audiencias']['virtualenv']) end
  action :run
end

execute "audiencias:deps" do
  command "#{node['config']['audiencias']['virtualenv']}/bin/pip install -r #{node['config']['audiencias']['dir']}/requirements.txt"
end

execute "audiencias:extra_deps" do
  command "#{node['config']['audiencias']['virtualenv']}/bin/pip install gunicorn psycopg2"
end

file "#{node['config']['audiencias']['dir']}/secret.key" do
  content "#{([*('A'..'Z'),*('0'..'9'),*('a'..'z')]-%w(0 1 I O)).sample(70).join}"
  action :create_if_missing
  owner "#{node['config']['system']['user']}"
  group "audiencias"
  mode '0755'
end

template "#{node['config']['audiencias']['dir']}/audiencias_publicas/settings.ini" do
  owner "#{node['config']['system']['user']}"
  group "audiencias"
  mode '0755'
  notifies :restart, 'service[audiencias]'
end

execute 'migrate' do
  command "#{node['config']['audiencias']['virtualenv']}/bin/python #{node['config']['audiencias']['dir']}/manage.py migrate"
  action :run
end

execute 'bower_install' do
  command "#{node['config']['audiencias']['virtualenv']}/bin/python #{node['config']['audiencias']['dir']}/manage.py bower install"
  user "#{node['config']['system']['user']}"
  group 'audiencias'
  action :run
end

execute 'collectstatic' do
  command "#{node['config']['audiencias']['virtualenv']}/bin/python #{node['config']['audiencias']['dir']}/manage.py collectstatic --noinput"
  user node['config']['system']['user']
  group 'audiencias'
  action :run
end

cookbook_file "#{node['config']['audiencias']['dir']}/gunicorn.py" do
  owner "#{node['config']['system']['user']}"
  group "audiencias"
  mode '0644'
  notifies :restart, 'service[audiencias]'
end

template '/etc/systemd/system/audiencias_cluster.service' do
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/systemd/system/audiencias_workers.service' do
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/systemd/system/audiencias.service' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[audiencias]'
end

service "crond"

template '/etc/cron.d/audiencias' do
  source 'audiencias-cron.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[crond]'
end

service 'redis' do
  supports :status => true, :restart => true, :reload => true
  action [:restart, :enable]
end

service 'audiencias' do
  supports :status => true, :restart => true, :reload => true
  action [:restart, :enable]
end
