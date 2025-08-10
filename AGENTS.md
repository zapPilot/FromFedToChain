# Repository Guidelines

This repository combines a Node.js CLI pipeline and a Flutter app. Follow the conventions below to keep contributions predictable and easy to review.

## Project Structure & Modules

- `src/`: Node.js CLI and services (`cli.js`, `ContentManager.js`, `services/`, `utils/`).
- `app/`: Flutter app (`lib/`, `test/`, `assets/`, `pubspec.yaml`).
- `tests/`: Node test suite run by `tests/run-tests.js`.
- `content/` and `audio/`: Source content and generated media.
- `cloudflare/`, `config/`, `docs/`, `.github/`: Infra, configs, docs, CI.

## Build, Test, and Dev Commands

- `npm run review`: Start interactive content review (CLI).
- `npm run pipeline <id>`: Full content pipeline (translate → TTS → hooks → streaming).
- `npm test`: Run Node + Flutter tests.
- `npm run test:node`: Execute Node tests.
- `npm run test:flutter`: Execute Flutter tests with coverage and checks.
- `npm run format`: Format JS (Prettier) and Dart (`dart format`).
- `npm run lint`: Node placeholder + `flutter analyze`.
- `npm run build:flutter`: Build Flutter web.
- `npm run install:flutter`: Fetch Flutter deps.

## Coding Style & Naming

- JavaScript: 2‑space indent, ES modules, Prettier enforced. Classes `PascalCase` (e.g., `ContentManager.js`), functions/vars `camelCase`. Tests use `kebab-case.test.js`.
- Dart: Follow `analysis_options.yaml`; files `snake_case.dart`. Prefer `final` where possible.
- Paths: Keep `src/services/*` focused and composable; avoid cross‑layer imports.

## Testing Guidelines

- Node: Add tests in `tests/*.test.js`; keep them deterministic and stateless.
- Flutter: Place widget/unit tests in `app/test/`; run `npm run test:flutter` locally.
- Coverage: Flutter coverage is checked via `app/scripts/coverage_check.dart`; don’t regress thresholds.

## Commit & Pull Requests

- Use Conventional Commits where possible: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `ci:`. Avoid `wip:` in main history.
- PRs must include: clear description, linked issues, test evidence (output or screenshots), and notes on config changes.
- Ensure `npm run format && npm run lint && npm test` pass before requesting review.

## Security & Configuration

- Copy env templates: `cp .env.sample .env` and `cp app/.env.example app/.env`.
- Never commit secrets; rely on local `.env` and CI secrets. Verify Cloudflare and Google credentials outside the repo.
