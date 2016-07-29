dependencies = ['git', 'python-pip', 'gcc-c++', 'python-devel',
                'libjpeg-devel', 'zlib-devel', 'nginx']

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
  group "#{node['config']['system']['user']}"
  group "wikilegis"
  action :sync
end

directory "#{node['config']['wikilegis']['dir']}/public" do
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
  action :create
end

execute "virtualenv #{node['config']['wikilegis']['virtualenv']}" do
  not_if do FileTest.directory?(node['config']['wikilegis']['virtualenv']) end
  action :run
end

execute "wikilegis:deps" do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/pip install -r #{node['config']['wikilegis']['dir']}/requirements.txt"
end

execute "wikilegis:extra_deps" do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/pip install gunicorn"
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

template "#{node['config']['wikilegis']['dir']}/wikilegis/settings.ini" do
  owner "#{node['config']['system']['user']}"
  group "wikilegis"
  mode '0755'
end

execute 'migrate' do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/python #{node['config']['wikilegis']['dir']}/manage.py migrate"
  action :run
end

execute 'collectstatic' do
  command "#{node['config']['wikilegis']['virtualenv']}/bin/python #{node['config']['wikilegis']['dir']}/manage.py collectstatic --noinput"
  user node['config']['system']['user']
  group 'wikilegis'
  action :run
end

cookbook_file "#{node['config']['wikilegis']['dir']}/gunicorn.py" do
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

service 'wikilegis' do
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end
