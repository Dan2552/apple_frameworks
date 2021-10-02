require "apple_frameworks"

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.filter_run_when_matching :focus
end
