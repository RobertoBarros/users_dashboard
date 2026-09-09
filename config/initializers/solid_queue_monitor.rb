SolidQueueMonitor.base_controller_class = "Admin::BaseController"

SolidQueueMonitor.setup do |config|
  config.authentication_enabled = false
  config.csrf_protection_enabled = true
end
