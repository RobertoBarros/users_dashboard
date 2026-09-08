require "faker"

user = User.find_or_initialize_by(email_address: "admin@admin.com")
user.role = :admin
user.full_name = "Administrator" if user.full_name.blank?
user.password = "123123123" if user.new_record?
unless user.avatar.attached?
  user.avatar.attach(io: File.open(Rails.root.join("db/seeds/avatar.png")), filename: "avatar.png", content_type: "image/png")
end
user.save!

50.times do |index|
  File.open(Rails.root.join("db/seeds/avatar.png")) do |avatar|
    User.find_or_create_by!(email_address: "seed-user-#{index + 1}@example.com") do |user|
      user.full_name = Faker::Name.name
      user.password = "123123123"
      user.role = User.roles.keys.sample
      user.avatar.attach(io: avatar, filename: "avatar.png", content_type: "image/png")
    end
  end
end
