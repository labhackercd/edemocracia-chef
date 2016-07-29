dependencies = ['epel-release', 'ruby', 'ruby-devel', 'nginx',
                'postgresql', 'postgresql-server', 'postgresql-contrib', 'redis',
                'ImageMagick', 'libxml2', 'gifsicle', 'libpqxx-devel', 'make',
                'libjpeg', 'policycoreutils-python', 'gcc-c++']

dependencies.each do |package_name|
  package "#{package_name}"
end

execute 'gem install bundler'

user 'discourse' do
  home "/home/#{node['config']['system']['user']}/"
  shell '/bin/bash'
end

group 'discourse' do
  action :create
  members ['discourse', node['config']['system']['user']]
end

directory "#{node['config']['discourse']['dir']}" do
  owner "#{node['config']['system']['user']}"
  group "discourse"
  mode '0755'
  action :create
end

git node['config']['discourse']['dir'] do
  repository node['config']['discourse']['repository']
  reference node['config']['discourse']['branch']
  user node['config']['system']['user']
  group 'discourse'
  action :sync
end

directory "#{node['config']['discourse']['dir']}/tmp" do
  owner "#{node['config']['system']['user']}"
  group "discourse"
  mode '0755'
  action :create
end

template "#{node['config']['discourse']['dir']}/config/database.yml" do
  user node['config']['system']['user']
  group 'discourse'
  mode '0644'
end

execute 'bundle install' do
  cwd node['config']['discourse']['dir']
  user node['config']['system']['user']
  group 'discourse'
  action :run
end

service 'redis' do
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end

execute 'bundle exec rake db:migrate' do
  user node['config']['system']['user']
  group 'discourse'
  environment ({"RAILS_ENV" => "production"})
  cwd node['config']['discourse']['dir']
  action :run
end

execute 'bundle exec rake assets:precompile' do
  user node['config']['system']['user']
  group 'discourse'
  environment ({"RAILS_ENV" => "production"})
  cwd node['config']['discourse']['dir']
  action :run
end

template '/etc/systemd/system/discourse.service' do
  owner 'root'
  group 'root'
  mode '0644'
end

service 'discourse' do
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end
