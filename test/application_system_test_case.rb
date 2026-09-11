require "test_helper"
require "capybara-playwright-driver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  parallelize(workers: 1)

  driven_by :playwright, using: :chromium, screen_size: [ 1400, 1000 ], options: {
    playwright_cli_executable_path: Rails.root.join("node_modules/.bin/playwright").to_s,
    channel: ENV["PLAYWRIGHT_CHANNEL"],
    headless: ENV["HEADED"] != "true"
  }

  Capybara.default_max_wait_time = 10
end
