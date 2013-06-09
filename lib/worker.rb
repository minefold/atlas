require './lib/render_map'

if ENV['BUGSNAG']
  require 'bugsnag'
  require 'bugsnag/sidekiq'

  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG']
  end
end