# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: "A4",
    landscape: true,
    margin: {
      top: "10mm",
      bottom: "10mm",
      left: "10mm",
      right: "10mm"
    },
    print_background: true,
    prefer_css_page_size: true,
    executable_path: ENV.fetch("PUPPETEER_EXECUTABLE_PATH", nil),
    # Docker環境でroot実行時に必要
    launch_args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
  }
end
