dependencies = ['git', 'unzip', 'gettext', 'libxml2-devel', 'libxslt-devel', 'openssl-devel', 'gcc', 'memcached',
                'libffi-devel', 'python-devel', 'python-pip', 'python-virtualenvwrapper', 'redis', 'elasticsearch']

cookbook_file '/etc/yum.repos.d/elasticsearch.repo' do
  owner 'root'
  group 'root'
  mode '0644'
end

dependencies.each do |package_name|
  package "#{package_name}" do
    retries 3
    retry_delay 2
  end
end

user 'colab' do
  home "/home/#{node['config']['system']['user']}/"
  shell '/bin/bash'
end

group 'colab' do
  action :create
  members ['colab', node['config']['system']['user']]
end

directory "#{node['config']['colab']['dir']}" do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
  action :create
end


git "#{node['config']['colab']['dir']}" do
  repository node['config']['colab']['repository']
  revision node['config']['colab']['branch']
  user "#{node['config']['system']['user']}"
  group 'colab'
  action :sync
end

execute "virtualenv #{node['config']['colab']['virtualenv']}" do
  not_if do FileTest.directory?(node['config']['colab']['virtualenv']) end
  action :run
end

execute "colab:deps" do
  command "#{node['config']['colab']['virtualenv']}/bin/pip install -e #{node['config']['colab']['dir']}"
end

execute "colab:extra_deps" do
  command "#{node['config']['colab']['virtualenv']}/bin/pip install psycopg2 gunicorn elasticsearch python-memcached"
end

directory '/var/log/colab' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
  action :create
end

file '/var/log/colab/colab.log' do
  action :create
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0664'
  notifies :restart, 'service[colab]'
end

directory '/etc/colab' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
  action :create
end

directory '/etc/colab/settings.d' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
  action :create
end

directory '/etc/colab/plugins.d' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
  action :create
end

file '/etc/colab/secret.key' do
  content "#{([*('A'..'Z'),*('0'..'9'),*('a'..'z')]-%w(0 1 I O)).sample(70).join}"
  action :create_if_missing
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
end

template '/etc/colab/settings.py' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
end

template '/etc/colab/settings.d/01-database.py' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
end

cookbook_file '/etc/colab/settings.d/02-logging.py' do
  action :create
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
end

cookbook_file '/etc/colab/settings.d/03-staticfiles.py' do
  action :create
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
end

cookbook_file '/etc/colab/settings.d/04-memcached.py' do
  action :create
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
end

execute 'migrate' do
  command "#{node['config']['colab']['virtualenv']}/bin/colab-admin migrate"
  user "#{node['config']['system']['user']}"
  action :run
end

execute 'collectstatic' do
  command "#{node['config']['colab']['virtualenv']}/bin/colab-admin collectstatic --noinput"
  user "#{node['config']['system']['user']}"
  action :run
end

cookbook_file '/etc/colab/gunicorn.py' do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0644'
end

template '/etc/systemd/system/colab.service' do
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/systemd/system/celerybeat.service' do
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/systemd/system/celeryd.service' do
  owner 'root'
  group 'root'
  mode '0644'
end

service 'redis' do
  supports :status => true, :restart => true
  action [:start, :enable]
end

service 'colab' do
  supports :status => true, :restart => true
  action [:start, :enable]
end

service 'elasticsearch' do
  supports :status => true, :restart => true
  action [:start, :enable]
end

template '/etc/nginx/conf.d/colab.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[nginx]'
end
