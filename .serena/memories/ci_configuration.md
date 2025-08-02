# CI/CD Configuration

## GitHub Actions Structure

The project uses three GitHub Actions workflows:

### 1. CI Workflow (`.github/workflows/ci.yml`)

- **test-nodejs**: Tests Node.js pipeline code from project root
- **test-flutter**: Tests Flutter app from `app/` directory
- **build**: Builds Flutter web app from `app/` directory

### 2. Quality Workflow (`.github/workflows/quality.yml`)

- Code formatting checks (Node.js + Flutter)
- Static analysis (Flutter analyze)
- Security audits
- Secret scanning

### 3. Coverage Workflow (`.github/workflows/coverage.yml`)

- Coverage reporting to Codecov

## Important Configuration Notes

### Working Directories

- **Node.js commands**: Run from project root (`)
- **Flutter commands**: Must use `working-directory: app` since Flutter project is in `app/` subdirectory

### Node.js Test Runner

- Uses built-in Node.js test runner with `node --test`
- **Do NOT use** `--test-isolation=none` flag (not supported in older Node.js versions)
- Test files pattern: `*.test.js` in `tests/` directory

### Flutter Paths

- **Dependencies**: `flutter pub get` in `app/` directory
- **Coverage**: Generated in `app/coverage/lcov.info`
- **Build artifacts**: Located in `app/build/web/`

## Common CI Failures and Fixes

### "node: bad option: --test-isolation=none"

- **Cause**: Flag not supported in Node.js 18
- **Fix**: Remove `--test-isolation=none` from test command

### "flutter pub get" fails

- **Cause**: Running Flutter commands from wrong directory
- **Fix**: Add `working-directory: app` to Flutter steps

### Path not found errors

- **Cause**: Artifact paths assume root directory
- **Fix**: Update paths to include `app/` prefix for Flutter artifacts
