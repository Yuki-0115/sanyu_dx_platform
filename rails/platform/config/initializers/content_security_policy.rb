# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, :https
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline  # Stimulus/Turbo用
    policy.style_src   :self, :unsafe_inline  # Tailwind CSS用
    policy.connect_src :self

    # 開発環境ではwebpack-dev-serverなど用に追加
    if Rails.env.development?
      policy.script_src :self, :unsafe_inline, :unsafe_eval
      policy.connect_src :self, "ws://localhost:*", "http://localhost:*"
    end

    # Specify URI for violation reports (optional)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy (uncomment for debugging).
  # config.content_security_policy_report_only = true
end
