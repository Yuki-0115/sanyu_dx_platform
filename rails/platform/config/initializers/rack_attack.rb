# frozen_string_literal: true

# Rack::Attack configuration for rate limiting
# VPS公開に伴うDoS/ブルートフォース対策

class Rack::Attack
  ### Throttle Spammy Clients ###

  # ログイン試行制限（5分間で5回まで）
  # Devise Lockableと併用してブルートフォース対策を強化
  throttle("logins/ip", limit: 5, period: 5.minutes) do |req|
    if req.path == "/auth/login" && req.post?
      req.ip
    end
  end

  # パスワードリセット制限（30分間で3回まで）
  throttle("password_reset/ip", limit: 3, period: 30.minutes) do |req|
    if req.path == "/auth/password" && req.post?
      req.ip
    end
  end

  # API制限（1分間で60回まで）
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # 全体のリクエスト制限（1分間で300回まで）
  # アセットは除外
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "リクエスト制限を超えました。しばらく待ってから再試行してください。" }.to_json]
    ]
  end
end
