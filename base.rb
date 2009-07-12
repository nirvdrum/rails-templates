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
<% jdbc = defined?(JRUBY_VERSION) ? 'jdbc' : '' %>

development:
  adapter: <%= jdbc %>postgresql
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
  adapter: <%= jdbc %>postgresql
  database: #{project_name}_test
  username: #{owner}
  password: #{owner} 
  host: localhost
  pool: 5
  timeout: 5000

production:
  adapter: <%= jdbc %>postgresql
  database: #{project_name}
  username: #{owner}
  password: #{owner}
  host: localhost
  pool: 5
  timeout: 5000
END

gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'shoulda'"

# Install Rails plugins
plugin 'less-for-rails', :git => 'git://github.com/augustl/less-for-rails.git'

# Install all gems
gem 'less'
gem 'mocha'
gem 'postgresql-ruby'
gem 'thoughtbot-shoulda'

rake 'gems:install', :sudo => true

# Set up Blueprint CSS.
inside('public/stylesheets') do
  run 'wget http://github.com/joshuaclayton/blueprint-css/tarball/master -O blueprint.tar.gz'
  run 'tar -zxf blueprint.tar.gz'
  run 'mv *-blueprint-* tmp'
  run 'mv tmp/blueprint .'
  run 'rm -rf tmp'
  run 'rm blueprint.tar.gz'
end

file 'app/views/layouts/application.erb', <<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>#{project_name}: <%= @page_title %></title>
  <%= stylesheet_link_tag 'blueprint/screen', :media => 'screen, projection' %>
  <%= stylesheet_link_tag 'blueprint/print', :media => 'print' %>
  <%= stylesheet_link_tag 'blueprint/plugins/fancy-type/screen', :media => 'screen, projection' %>
</head>
<body>

<div class="container">
  <div id="header" class="span-24 last">
    <% if flash[:notice] %>
      <div id="flash_message" class="success"><%= flash[:notice] %></div>
    <% end %>

    <% if flash[:error] %>
      <div id="flash_message" class="error"><%= flash[:error] %></div>
    <% end %>

    <h1><%= @page_title %></h1>
    <hr />
  </div>

  <div class="span-20 last">
    <%= yield %>
  </div>
</div>

</body>
</html>

END
  

# Now commit everything.
git :add => '.'
git :commit => "-a -m 'Initial commit.'"
 
# Success!
puts "SUCCESS!"