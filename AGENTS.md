# Repository Guidelines

## Project Structure & Module Organization

- `src/`: Node.js CLI and services (`cli.js`, `ContentManager.js`, `services/`, `utils/`).
- `app/`: Flutter app (`lib/`, `test/`, `assets/`, `pubspec.yaml`).
- `tests/`: Node test suite run by `tests/run-tests.js`.
- `content/`, `audio/`: Source content and generated media.
- `cloudflare/`, `config/`, `docs/`, `.github/`: Infra, configs, docs, CI.

## Build, Test, and Development Commands

- `npm run review`: Launch interactive content review CLI.
- `npm run pipeline <id>`: Run full pipeline (translate → TTS → hooks → streaming). Example: `npm run pipeline 12345`.
- `npm test`: Run Node + Flutter tests.
- `npm run test:node`: Execute Node tests only.
- `npm run test:flutter`: Run Flutter tests with coverage checks.
- `npm run format`: Prettier for JS + `dart format`.
- `npm run lint`: Node placeholder + `flutter analyze`.
- `npm run build:flutter`: Build Flutter for web.
- `npm run install:flutter`: Fetch Flutter dependencies.

## Coding Style & Naming Conventions

- JavaScript: 2‑space indent, ES modules, Prettier enforced. Classes `PascalCase` (e.g., `ContentManager.js`); functions/vars `camelCase`. Tests use `kebab-case.test.js`.
- Dart: Follow `analysis_options.yaml`; files `snake_case.dart`; prefer `final` where possible.
- Structure: Keep `src/services/*` focused and composable; avoid cross‑layer imports.

## Testing Guidelines

- Node: Add deterministic tests in `tests/*.test.js`; run with `npm run test:node`.
- Flutter: Place tests in `app/test/`; run `npm run test:flutter` locally.
- Coverage: Enforced by `app/scripts/coverage_check.dart`; do not regress thresholds.

## Commit & Pull Request Guidelines

- Commits: Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`). Avoid `wip:` in main history.
- PRs must include: clear description, linked issues, test evidence (output/screenshots), and notes on config changes.
- Pre‑PR checks: `npm run format && npm run lint && npm test` must pass.

## Security & Configuration

- Create envs: `cp .env.sample .env` and `cp app/.env.example app/.env`.
- Never commit secrets; rely on local `.env` and CI secrets.
- Validate Cloudflare/Google creds outside the repo.
