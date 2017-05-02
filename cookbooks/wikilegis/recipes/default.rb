dependencies = ['git', 'python-pip', 'python34', 'python34-devel', 'gcc-c++',
                'nginx']

dependencies.each do |package_name|
  package "#{package_name}"
end

user 'wikilegis' do
  home "/home/#{node['config']['system']['user']}/"
  shell '/bin/bash'
end

group 'wikilegis' do
  action :create
  members ['wikilegis', node['config']['system']['user']]
end

git "#{node['config']['wikilegis']['dir']}" do
  repository node['config']['wikilegis']['repository']
  revision node['config']['wikilegis']['branch']
  action :sync
end

directory "#{node['config']['wikilegis']['dir']}/wikilegis/public" do
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
  action :create
end

directory "#{node['config']['wikilegis']['dir']}/wikilegis/static/bower_components" do
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
  action :create
end

execute "update:virtualenv" do
  command "pip install -U virtualenv"
end

execute "virtualenv #{node['config']['wikilegis']['virtualenv']} -p python3" do
  not_if do FileTest.directory?(node['config']['wikilegis']['virtualenv']) end
  action :run
end

execute "update:pip" do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/pip install -U pip"
end

execute "wikilegis:deps" do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/pip install -r #{node['config']['wikilegis']['dir']}/requirements.txt"
end

execute "wikilegis:extra_deps" do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/pip install gunicorn psycopg2"
end

file "#{node['config']['wikilegis']['dir']}/secret.key" do
  content "#{([*('A'..'Z'),*('0'..'9'),*('a'..'z')]-%w(0 1 I O)).sample(70).join}"
  action :create_if_missing
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
end

file "#{node['config']['wikilegis']['dir']}/api.key" do
  content "#{([*('A'..'Z'),*('0'..'9'),*('a'..'z')]-%w(0 1 I O)).sample(70).join}"
  action :create_if_missing
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
end

file "#{node['config']['wikilegis']['dir']}/wikilegis/wikilegis.log" do
  action :create_if_missing
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
end

file "#{node['config']['wikilegis']['dir']}/wikilegis/.plugins" do
  action :create_if_missing
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
end

execute "npm:install" do
  cwd "#{node['config']['wikilegis']['dir']}"
  command "npm install"
end


template "#{node['config']['wikilegis']['dir']}/wikilegis/wikilegis/settings/settings.ini" do
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
end

execute 'migrate' do
  cwd "#{node['config']['wikilegis']['dir']}/wikilegis/"
  command "#{node['config']['wikilegis']['virtualenv']}/bin/python manage.py migrate"
  action :run
end

execute 'compilemessages' do
  cwd "#{node['config']['wikilegis']['dir']}/wikilegis/"
  command "#{node['config']['wikilegis']['virtualenv']}/bin/python manage.py compilemessages"
  action :run
end

execute 'collectstatic' do
  cwd "#{node['config']['wikilegis']['dir']}/wikilegis/"
  command "#{node['config']['wikilegis']['virtualenv']}/bin/python manage.py collectstatic --noinput"
  user node['config']['system']['user']
  group 'wikilegis'
  action :run
end

cookbook_file "#{node['config']['wikilegis']['dir']}/wikilegis/gunicorn.py" do
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0644'
  notifies :restart, 'service[wikilegis]'
end

template '/etc/systemd/system/wikilegis.service' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[wikilegis]'
end

service "crond"

template '/etc/cron.d/wikilegis' do
  source 'wikilegis-cron.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[crond]'
end

service 'wikilegis' do
  supports :status => true, :restart => true, :reload => true
  action [:restart, :enable]
end
