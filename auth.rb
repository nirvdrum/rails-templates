load_template "http://github.com/nirvdrum/rails-templates/raw/master/basic.rb"

# Install all gems
gem 'authlogic'

rake 'gems:install', :sudo => true