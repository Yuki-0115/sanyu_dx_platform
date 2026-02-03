# frozen_string_literal: true

# whenever gem configuration
# crontab更新: bundle exec whenever --update-crontab
# crontab確認: bundle exec whenever
# crontab削除: bundle exec whenever --clear-crontab

set :output, "log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "production")

# 毎日AM6:00に有給関連の日次処理を実行
every 1.day, at: "6:00 am" do
  rake "paid_leave:daily"
end
