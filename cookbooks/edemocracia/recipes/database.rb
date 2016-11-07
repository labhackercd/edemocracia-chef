execute "postgresql-setup initdb || true"

template "/var/lib/pgsql/data/pg_hba.conf" do
  user "postgres"
  group "postgres"
  mode 0600
  notifies :restart, "service[postgresql]"
end

template "/var/lib/pgsql/data/postgresql.conf" do
  user "postgres"
  group "postgres"
  mode 0600
  notifies :restart, 'service[postgresql]', :immediately
end

service "postgresql" do
  action [:enable, :start]
  supports :restart => true
end

# Create database users for all applications
applications_usernames = ['colab', 'wikilegis', 'discourse', 'audiencias', node['config']['system']['user']]

applications_usernames.each do |username|
  execute "createuser:#{username}" do
    command "createuser -s #{username}"
    user 'postgres'
    only_if do
      `sudo -u postgres -i psql --quiet --tuples-only -c "select count(*) from pg_user where usename = '#{username}';"`.strip.to_i == 0
    end
  end
end

# Create databases for all applications
applications_database = {colab: 'colab', wikilegis: 'wikilegis', discourse: 'discourse', audiencias: 'audiencias'}

applications_database.each do |username, database|
  execute "createdb:#{database}" do
    command "createdb --owner=#{username} #{database}"
    user 'postgres'
    only_if do
      `sudo -u postgres -i psql --quiet --tuples-only -c "select count(1) from pg_database where datname = '#{database}';"`.strip.to_i == 0
    end
  end
end