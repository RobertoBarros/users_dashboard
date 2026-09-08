user = User.find_or_initialize_by(email_address: "admin@admin.com")
user.role = :admin
user.password = "123123123" if user.new_record?
user.save!
