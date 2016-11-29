dependencies = ['epel-release', 'python', 'python-devel', 'python-pip', 'nginx',
                'postgresql', 'postgresql-server', 'postgresql-contrib', 'redis',
                'ImageMagick', 'libxml2', 'gifsicle', 'libpqxx-devel', 'make',
                'libjpeg', 'policycoreutils-python']

dependencies.each do |package_name|
  package "#{package_name}"
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end

cookbook_file '/etc/nginx/nginx.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[nginx]'
end

cookbook_file '/tmp/edem_nginx.pp' do
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/tmp/edem_nginx.te' do
  owner 'root'
  group 'root'
  mode '0644'
end

execute 'semodule -i edem_nginx.pp' do
  cwd "/tmp/"
  action :run
end

cookbook_file '/tmp/audiencias.pp' do
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/tmp/audiencias.te' do
  owner 'root'
  group 'root'
  mode '0644'
end

execute 'semodule -i audiencias.pp' do
  cwd "/tmp/"
  action :run
end
