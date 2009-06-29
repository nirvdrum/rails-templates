# Delete unnecessary files
run "rm README"
run "rm -rf doc"
run "rm public/index.html"
run "rm public/favicon.ico"

# Set up git repository
git :init

# Copy database.yml for distribution use
run "cp config/database.yml config/database.yml.example"

file '.gitignore', <<-END
.DS_Store
.idea
*.sqlite3
log
tmp
config/database.yml
END

# Install Rails plugins
plugin 'less-for-rails', :git => 'git://github.com/augustl/less-for-rails.git'

# Install all gems
gem 'less'

rake('gems:install', :sudo => true)

# Commit all work so far to the repository
git :add => '.'
git :commit => "-a -m 'Initial commit.'"
 
# Success!
puts "SUCCESS!"