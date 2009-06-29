project_name = @root.split('/').last
owner = `whoami`.strip

# Delete unnecessary files
run "rm README"
run "rm -rf doc"
run "rm public/index.html"
run "rm public/favicon.ico"

# Set up git.
git :init

file '.gitignore', <<-END
.DS_Store
.idea
*.sqlite3
log
tmp
END

# Copy database.yml for distribution use
run "cp config/database.yml config/database.yml.example"

# Set up database.yml file for PostgreSQL.
file 'config/database.yml', <<-END
#   gem install postgresql-ruby (not necessary on OS X Leopard)
development:
  adapter: postgresql
  database: #{project_name}
  username: #{owner}
  password: #{owner}
  host: localhost
  pool: 5
  timeout: 5000

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: postgresql
  database: #{project_name}_test
  username: #{owner}
  password: #{owner} 
  host: localhost
  pool: 5
  timeout: 5000

production:
  adapter: postgresql
  database: #{project_name}
  username: #{owner}
  password: #{owner}
  host: localhost
  pool: 5
  timeout: 5000
END

# Install Rails plugins
plugin 'less-for-rails', :git => 'git://github.com/augustl/less-for-rails.git'

# Install all gems
gem 'less'
gem 'mocha'
gem 'postgresql-ruby'
gem 'shoulda'

rake 'gems:install', :sudo => true

# Set up Blueprint CSS.
inside('public/stylesheets') do
  run 'wget http://github.com/joshuaclayton/blueprint-css/tarball/master -O blueprint.tar.gz'
  run 'tar -zxf blueprint.tar.gz'
  run 'mv *blueprint* tmp'
  run 'mv tmp/blueprint .'
  run 'rm -rf tmp'
end
  

# Now commit everything.
git :add => '.'
git :commit => "-a -m 'Initial commit.'"
 
# Success!
puts "SUCCESS!"