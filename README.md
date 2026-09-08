# Users Dashboard

A Rails application with a home page, navbar, and theme picker with color previews and saved preferences.

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
