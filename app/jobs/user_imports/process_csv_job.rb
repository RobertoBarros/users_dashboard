class UserImports::ProcessCsvJob < ApplicationJob
  def perform(user_import)
    return if user_import.completed?

    user_import.prepare!.each_with_index do |(full_name, email_address), index|
      position = index + 1
      next if user_import.results.key?(position.to_s)

      UserImports::CreateUserJob.perform_later(user_import, position, full_name, email_address)
    end
  rescue UserImport::InvalidCsvError => error
    user_import.update!(status: :failed, error_message: error.message)
  rescue StandardError
    user_import.update!(status: :failed, error_message: "Import interrupted. An administrator can retry the job in the job monitor.")
    raise
  end
end
