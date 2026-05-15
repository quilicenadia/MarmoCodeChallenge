ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Ruby 3.2 does not load Logger by default; Rails 6.1 still expects it (ActiveSupport).
require "logger"
require "bundler/setup"
require "bootsnap/setup"
