# Users Dashboard

A Rails application with user registration, authentication, profiles, and an admin dashboard.

## Disclaimer

OpenAI Codex (GPT-6) helped write the code, tests, and documentation. A human made all decisions about the architecture, features, and code.

## Stack

- Ruby 4.0.6 and Rails 8.1.
- PostgreSQL for the database.
- Solid Queue for background jobs through Active Job.
- ERB, Tailwind CSS 4, and daisyUI 5 for the interface.
- JavaScript ES6, Stimulus, and Turbo for interactivity.
- Importmap and Propshaft for JavaScript and assets.
- Puma as the web server.

The repository includes daisyUI, which Tailwind compiles. You do not need to set up Node.js.

## Features

### Profiles and appearance

- Edit your name, email, password, and optional avatar. Profile pages update when an admin changes your account.
- Accounts without an avatar show their initials.
- Choose a theme with color previews. The browser saves your choice and uses your system's light or dark preference by default.
- Forms show validation errors below the affected inputs.

### User administration

- The admin dashboard is restricted to administrators.
- Edit a user's details, role, password, and avatar directly in the user list without leaving the page.

### CSV imports

- Upload names and emails in either column order; the import detects the email column automatically.
- Users are imported in parallel in the background, with live progress and validation errors for each failed row, including duplicate emails.
- Leave the page and return to follow an ongoing import.
- Try [`examples/users.csv`](examples/users.csv) with 500 records, including 100 intentional validation failures (20%).

## Development

With Ruby and PostgreSQL available:

```sh
bundle install
bin/rails db:prepare
bin/dev
```

Open http://localhost:3000.

Run `bin/rails db:seed` to create an administrator and 50 users with Faker names, random roles, and a default avatar. The users have addresses from `seed-user-1@example.com` through `seed-user-50@example.com`, all with password `123123123`. Running the seeds again does not duplicate accounts.

## Docker

With Docker running:

```sh
docker compose up --build
```

Open http://localhost:3000 and sign in as `admin@admin.com` with password `123123123`.
Docker runs Rails in production mode with PostgreSQL and a Solid Queue worker. [Thruster](https://github.com/basecamp/thruster) handles asset caching and compression. Startup prepares the local secret and databases, then runs the seeds without duplicating users. Docker volumes store the secret, database data, and uploads shared between the app and worker.

Logs appear in the terminal. Press `Ctrl+C` to stop the containers and keep their data. Run the same command after code changes. Set `APP_PORT` in `.env` to use another port.

## Background jobs

Sign in as an admin and visit `/admin/jobs` to view jobs in Solid Queue Monitor.

## Tests

With PostgreSQL running, run the Minitest suite:

```sh
bin/rails db:test:prepare test
```

[SimpleCov](https://github.com/simplecov-ruby/simplecov) measures Ruby code coverage automatically. Open `coverage/index.html` in your browser after running the tests to view the report.
