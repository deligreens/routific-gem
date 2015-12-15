require 'bundler/setup'
Bundler.setup

require 'faker'

require 'dotenv'
Dotenv.load

require 'routific'
require 'pry'

require_relative './factory'

RSpec.configure do |config|
end
