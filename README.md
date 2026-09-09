# Users Dashboard

A Rails application with user registration, authentication, profiles, and an admin dashboard.

## Features

- **Home and navigation:** public home page with navigation that adapts to the signed-in user's role.
- **Sign up:** registration with full name, unique email, password confirmation, and an optional avatar. Successful registration signs the user in automatically.
- **Authentication:** email and password login, persistent sessions, logout, and rate limits on login and sign-up requests.
- **Profile:** view and edit your full name, email, password, and avatar. Leaving the password or avatar unchanged preserves the current value. Open profile pages receive Turbo refresh broadcasts when the user is updated, including edits made by an admin.
- **Avatars:** Active Storage uploads supporting JPEG, PNG, GIF, and WebP, displayed as circular avatars. Users without an image display a daisyUI placeholder with their initials.
- **Roles and access:** new accounts receive the `user` role. The admin dashboard is restricted to `admin` accounts; login redirects users according to their role.
- **Admin user editing:** each user in the admin list has an Edit button that opens a form in place using Turbo Streams. Admins can update full name, email, role, password, and avatar. Blank password and avatar fields preserve their current values. Model validation errors appear in red below the corresponding inputs; saving or canceling restores the user row without leaving the list.
- **User import:** admins can select **Import users** on the dashboard to upload a CSV with name and email columns in either order. Imports run in the background with one job per user for parallel processing, live progress and validation errors, and remain accessible after leaving the page. Try [`examples/users.csv`](examples/users.csv) with 500 records, including 100 intentional validation failures (20%).
- **Validation:** required full name, normalized and unique email addresses, and passwords of at least 8 characters, with form error messages.
- **Themes:** daisyUI theme picker with color previews, saved browser preferences, and system light/dark preference as the default.
- **Seeds:** an initial administrator and 50 users with Faker names, random roles, and a default avatar. Seed users use `seed-user-1@example.com` through `seed-user-50@example.com` with password `123123123`. Run `bin/rails db:seed`; repeated runs do not duplicate these accounts.

## Stack

- Ruby 4.0.6 and Rails 8.1.
- PostgreSQL for the database.
- Solid Queue for background jobs through Active Job.
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

## Background jobs

Sign in as an admin and visit `/admin/jobs` to view jobs in Solid Queue Monitor.
