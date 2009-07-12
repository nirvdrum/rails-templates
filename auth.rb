load_template "http://github.com/nirvdrum/rails-templates/raw/master/basic.rb"

# Set up authlogic/test_case in test_helper.
gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'authlogic/test_case'"

# Install all gems
gem 'authlogic'

rake 'gems:install', :sudo => true