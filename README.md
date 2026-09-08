# Users Dashboard

A Rails application with user registration, authentication, profiles, and an admin dashboard.

## Features

- **Home and navigation:** public home page with navigation that adapts to the signed-in user's role.
- **Sign up:** registration with full name, unique email, password confirmation, and a required avatar. Successful registration signs the user in automatically.
- **Authentication:** email and password login, persistent sessions, logout, and rate limits on login and sign-up requests.
- **Profile:** view and edit your full name, email, password, and avatar. Leaving the password or avatar unchanged preserves the current value.
- **Avatars:** Active Storage uploads supporting JPEG, PNG, GIF, and WebP, displayed as circular avatars on the profile.
- **Roles and access:** new accounts receive the `user` role. The admin dashboard is restricted to `admin` accounts; login redirects users according to their role.
- **Validation:** required full name and avatar, normalized and unique email addresses, and passwords of at least 8 characters, with form error messages.
- **Themes:** daisyUI theme picker with color previews, saved browser preferences, and system light/dark preference as the default.
- **Seeds:** an initial administrator and 50 users with Faker names, random roles, and a default avatar. Seed users use `seed-user-1@example.com` through `seed-user-50@example.com` with password `123123123`. Run `bin/rails db:seed`; repeated runs do not duplicate these accounts.

## Stack

- Ruby 4.0.6 and Rails 8.1.
- PostgreSQL for the database.
- ERB, Tailwind CSS 4, and daisyUI 5 for the interface.
- JavaScript ES6, Stimulus, and Turbo for interactivity.
- Importmap and Propshaft for JavaScript and assets.
- Puma as the web server.

daisyUI is included in the repository and compiled with Tailwind. No Node.js setup is required.

## Development

With Ruby and PostgreSQL available:

```sh
bundle install
bin/rails db:prepare
bin/dev
```

Open http://localhost:3000.
