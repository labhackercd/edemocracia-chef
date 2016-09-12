directory "#{node['config']['colab']['plugins_dir']}" do
  owner "#{node['config']['system']['user']}"
  group "colab"
  mode '0755'
  action :create
end

package ['nodejs', 'npm']

execute 'install:bower' do
  command 'npm install -g bower'
  action :run
end

node['config']['plugins'].each do |plugin|
  directory "#{node['config']['colab']['plugins_dir']}/#{plugin['name']}" do
    owner "#{node['config']['system']['user']}"
    group "colab"
    mode '0755'
    action :create
  end

  git "#{node['config']['colab']['plugins_dir']}/#{plugin['name']}"  do
    repository plugin['url']
    reference plugin['branch']
    user "#{node['config']['system']['user']}"
    group 'colab'
    action :sync
  end

  template "/etc/colab/plugins.d/#{plugin['name']}.py" do
    owner "#{node['config']['system']['user']}"
    group "colab"
    mode '0644'
    get_discourse_api_token = lambda do
      Dir.chdir node['config']['discourse']['dir'] do
        `RAILS_ENV=production /usr/local/bin/bundle exec rake api_key:get`.strip
      end
    end
    variables({
      :plugin_name => plugin['name'],
      :get_discourse_api_token => get_discourse_api_token
    })
  end

  execute "install-plugin:#{plugin['name']}" do
    cwd "#{node['config']['colab']['plugins_dir']}/#{plugin['name']}"
    command "#{node['config']['colab']['virtualenv']}/bin/pip install -e ."
    action :run
  end
end

execute 'bower_install' do
  command "#{node['config']['colab']['virtualenv']}/bin/colab-admin bower install"
  user "#{node['config']['system']['user']}"
  group 'colab'
end

execute 'migrate' do
  command "#{node['config']['colab']['virtualenv']}/bin/colab-admin migrate"
  user "#{node['config']['system']['user']}"
end

execute 'collectstatic' do
  command "#{node['config']['colab']['virtualenv']}/bin/colab-admin collectstatic --noinput"
  user "#{node['config']['system']['user']}"
end

service 'colab' do
  supports :status => true, :restart => true, :reload => true
  action [:restart, :enable]
end

service 'elasticsearch' do
  action :restart
end
