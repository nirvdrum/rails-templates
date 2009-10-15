# Copyright 2009 Kevin J. Menard Jr.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


load_template 'http://github.com/nirvdrum/rails-templates/raw/master/base.rb'

# Set up authlogic/test_case in test_helper.
gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'authlogic/test_case'"

# Install all gems
gem 'authlogic'

rake 'gems:install', :sudo => true

# Install all plugins
plugin 'authlogic_generator', :git => 'git://github.com/masone/authlogic_generator.git'

generate :authlogic