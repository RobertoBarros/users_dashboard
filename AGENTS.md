# Project conventions

- Keep application UI, documentation, variable names, and method names in English.
- Prefer Ruby/Rails, JavaScript ES6, Stimulus, Tailwind CSS, and daisyUI.
- Make the smallest necessary changes; avoid unnecessary dependencies and abstractions.
- Keep the UI simple and minimal. Use icons and theme previews where appropriate.
- When working with daisyUI, use the official `saadeghi/daisyui` skill at https://github.com/saadeghi/daisyui/blob/master/skills/daisyui/SKILL.md and its applicable component guides.
- Use Importmap for browser JavaScript. Keep the daisyUI Tailwind plugin in Git.
- Keep tests minimal and focused on application business rules, not Rails behavior.
- Version `db/schema.rb`.
- Keep documentation simple and minimal.
- Record only project-wide development conventions in this file; exclude business rules and page-specific behavior.
- Use Pagy for pagination with deterministic ordering and a unique tie-breaker.
- Render repeated records with collection partials and stable `dom_id(record)` IDs.
- Eager-load associations used by collection partials to avoid N+1 queries.
- Prefer daisyUI components and semantic colors that follow the active theme.
- Send model broadcasts after commit. Prefer Turbo refreshes with morphing and scroll preservation when multiple page sections must update together.
