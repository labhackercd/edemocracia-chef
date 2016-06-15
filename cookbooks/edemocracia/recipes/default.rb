dependencies = ['epel-release', 'python', 'python-devel', 'python-pip', 'nginx',
                'postgresql', 'postgresql-server', 'postgresql-contrib', 'redis',
                'ImageMagick', 'libxml2', 'gifsicle', 'libpqxx-devel', 'make',
                'libjpeg',]

dependencies.each do |package_name|
  package "#{package_name}"
end

