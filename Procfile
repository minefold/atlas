web: bundle exec puma -p $PORT ./config.ru
worker: bundle exec sidekiq -c $SIDEKIQ_WORKERS -r ./lib/render_map.rb