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

# Set up shoulda in test_helper.
gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'shoulda'"

# Install Rails plugins
plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'
plugin 'more', :git => 'git://github.com/logandk/more.git'

# Install all gems
gem 'less'
gem 'postgres-pr'

gem 'mocha', :env => 'test'
gem 'thoughtbot-shoulda', :env => 'test'

rake 'gems:install', :sudo => true

# Set up Hoptoad notifier.
initializer 'hoptoad.rb', <<-END
HoptoadNotifier.configure do |config|
  break if RAILS_ENV == 'test'

  config.api_key = RAILS_ENV == 'production' ? 'PRODUCTION_KEY' : 'STAGING_KEY'
  # config.secure = true  # Must have a Toad or Bullfrog account for SSL support.

  # Disable certain environment variables from showing up in Hoptoad.
  config.environment_filters << "AWS_SECRET"
  config.environment_filters << "EC2_PRIVATE_KEY"
  config.environment_filters << "AWS_ACCESS"
  config.environment_filters << "EC2_CERT"
end
END

# Set up jQuery.
inside('public/javascripts') do
  run 'rm *'
  run 'wget http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js'
  run 'http://github.com/malsup/form/raw/master/jquery.form.js'
end

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

  <%= javascript_include_tag 'jquery-1.3.2.min' %>

  <%= yield :head %>
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
  

# Set up capistrano.
run 'capify .'

file 'config/deploy.rb', <<-END
set :application, '"#{project_name}"'

set :user, '#{owner}'

ssh_options[:forward_agent]  = true

set :repository,  "#{owner}@ssh.negativetwenty.net:/var/git/#{project_name}.git"
set :scm, "git"
set :deploy_via, :remote_cache
set :git_enable_submodules, true

branch = `git branch`.grep(/\*/).first.chomp.gsub(/\* */, '')
set :branch, branch

# If you aren't deploying to /u/apps/#\{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/\#{application}/www"

set :runner, user

role :app, application
role :web, application
role :db,  application, :primary => true

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch \#{current_path}/tmp/restart.txt"
  end
end

desc "After updating code we need to populate a new database.yml"
task :after_update_code, :roles => :app do
  require "yaml"
  set :production_database_password, proc { Capistrano::CLI.password_prompt("Production database remote Password : ") }
  buffer = YAML::load_file('config/database.yml')
  # get ride of uneeded configurations
  buffer.delete('test')
  buffer.delete('development')
  
  # Populate production element
  buffer['production']['adapter'] = "postgresql"
  buffer['production']['database'] = "negativetwenty_www"
  buffer['production']['username'] = "nirvdrum"
  buffer['production']['password'] = production_database_password
  buffer['production']['host'] = "localhost"
  
  put YAML::dump(buffer), "\#{release_path}/config/database.yml", :mode => 0664
end

desc "After a deploy, we need to re-establish the symlink to Redmine."
task :after_deploy, :roles => :app do
  redmine_path = "\#{deploy_to}/../redmine/public"  
  run "ln -s \#{redmine_path} \#{release_path}/public/redmine"
end


# Taken from: http://github.com/jtimberman/ree-capfile/blob/master/Capfile

# Author: Joshua Timberman <joshua@hjksolutions.com>
#
# Copyright 2008, HJK Solutions
# Portions originally written by spiceee, 
#   http://snippets.dzone.com/posts/show/6372
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Change to latest release or desired prior version for download link below.
ree_dl_id = "58677"
ree_version = "1.8.6-20090610"
 
ree_tarball = "ruby-enterprise-\#{ree_version}.tar.gz"
ree_source = "http://rubyforge.org/frs/download.php/\#{ree_dl_id}/\#{ree_tarball}"
ree_path = "/opt/ruby-enterprise"
# Change to the location of the "system" installed Ruby.
old_gem = "/usr/bin/gem"
new_gem = "\#{ree_path}-\#{ree_version}/bin/gem"
 
# Uncomment to use the local gems server, also uncomment cmd in ree_gems task.
#gem_source = "http://gems"
 
desc "Install Ruby Enterprise Edition"
task :ree_install, :roles => :app do
  logger.info("Installing Ruby Enterprise Edition from source")
  run("mkdir -p /tmp/ree")
  run("sh -c '(cd /tmp/ree; wget \#{ree_source} 2>/dev/null)'")
  run("sh -c '(cd /tmp/ree; tar zxf \#{ree_tarball})'")
  sudo("sh -c '(cd /tmp/ree/ruby-enterprise-\#{ree_version}; ./installer -a \#{ree_path}-\#{ree_version})'")
  sudo("ln -sf \#{ree_path}-\#{ree_version} \#{ree_path}")
  sudo("rm -rf /tmp/ree")
end
 
desc "Install System Gems in REE"
task :ree_gems, :roles => :app do
  oldgems = capture "\#{old_gem} list"
  newgems = capture "\#{new_gem} list"
  # oldgems.each block written by spiceee.
  # http://snippets.dzone.com/posts/show/6372
  oldgems.each do |line|
    matches = line.match(/([A-Z].+) \(([0-9\., ]+)\)/i)
    if matches 
    then
      gem_name = matches[1]
      versions = matches[2]
      versions.split(', ').each do |ver|
        cmd = "\#{new_gem} install \#{gem_name} --version \#{ver}" # --source \#{gem_source}"
        # rubygems-update is "installed" because REE includes RubyGems 1.3.1.
        if newgems =~ /\#{gem_name} \(.*\#{ver}.*\)/i || gem_name =~ /rubygems-update/
        then
          logger.info("\#{gem_name} \#{ver} is already installed. Skipping.")
        else
          sudo(cmd)
        end
      end
    end
  end # oldgems.each
end
 
desc "Install REE and system gems"
task :ree_install_all, :roles => :app do
  ree_install
  ree_gems
end



desc "Install munin"
task :install_munin do
  sudo "apt-get install munin munin-node munin-plugins-extra tofromdos -y"
end

desc "Install munin plugins"
task :install_munin_plugins do  
  plugins = {'passenger_status' => 20319, 'passenger_memory_stats' => 21391}
  
  plugins.each do |plugin_name, gist_id|
    plugin = "/usr/share/munin/plugins/\#{plugin_name}"
    link = "/etc/munin/plugins/\#{plugin_name}"
    sudo "wget http://gist.github.com/\#{gist_id}.txt"
    sudo "mv \#{gist_id}.txt \#{plugin}"
    sudo "chmod a+x \#{plugin}"
    sudo "fromdos \#{plugin}"
    sudo "rm -rf \#{link}"
    sudo "ln -s \#{plugin} \#{link}"
    puts " ------- !!!!sudo visudo ---> munin ALL=(ALL) NOPASSWD:/usr/bin/passenger-status, /usr/bin/passenger-memory-stats"
  end
end
END


# Now commit everything.
git :add => '.'
git :commit => "-a -m 'Initial commit.'"
 
# Success!
puts "SUCCESS!"