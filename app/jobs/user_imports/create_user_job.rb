class UserImports::CreateUserJob < ApplicationJob
  def perform(user_import, position, full_name, email_address)
    user_import.import_user!(position, full_name, email_address)
  rescue StandardError
    user_import.update!(status: :failed, error_message: "Import interrupted. An administrator can retry the job in the job monitor.")
    raise
  end
end
