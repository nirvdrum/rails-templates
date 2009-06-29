project_name = @root.split('/').last
owner = `whoami`

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

# Now commit everything.
git :add => '.'
git :commit => "-a -m 'Initial commit.'"
 
# Success!
puts "SUCCESS!"