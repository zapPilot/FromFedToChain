# Testing Infrastructure & CI/CD Documentation

## Overview

From Fed to Chain implements a comprehensive testing and continuous integration strategy covering both Node.js CLI pipeline and Flutter mobile/web app. The system ensures code quality, prevents regressions, and maintains deployment readiness.

## Node.js Testing Suite (`tests/`)

### Test Files & Coverage

**Core Tests**:

- `content-schema.test.js` - Schema validation and structure testing
- `contentmanager-nested.test.js` - Content CRUD operations and file management
- `pipeline.test.js` - End-to-end pipeline processing
- `cli-commands.test.js` - CLI interface and command parsing
- `review.test.js` - Interactive review workflow testing

**Service Tests**:

- `translation.test.js` - Google Translate API integration
- `tts-batching.test.js` - Text-to-speech service with batching
- `audio-architecture.test.js` - Audio processing and conversion

**Integration Tests**:

- `end-to-end-workflow.test.js` - Complete content lifecycle
- `config.test.js` - Configuration validation
- `sanity-checks.test.js` - System health checks

**Test Infrastructure**:

- `setup.js` - Test environment configuration
- `run-tests.js` - Custom test runner with reporting
- `manual-review-test.js` - Interactive testing utilities

### Test Metrics

- **Total Tests**: 174 passing, 12 skipped
- **Coverage**: Comprehensive service and integration coverage
- **Test Types**: Unit, integration, and end-to-end tests
- **Mock Strategy**: Service mocking for external APIs

### Test Runner Configuration

```javascript
// Custom test runner with:
// - Parallel test execution
// - Detailed reporting
// - Error aggregation
// - Coverage reporting
```

## Flutter Testing Suite (`app/test/`)

### Test Structure

- **Model Tests**: AudioContent, AudioFile, Playlist validation
- **Widget Tests**: Component behavior and interaction testing
- **Service Tests**: AudioService, ContentService unit tests
- **Integration Tests**: Service interaction and data flow

### Test Configuration

- **Framework**: Flutter Test with Mockito
- **Coverage**: LCOV reporting with coverage gates
- **Mocking**: Service mocking for isolated testing
- **Widget Testing**: Comprehensive UI component testing

### Coverage Requirements

- **Coverage Check**: Automated via `scripts/coverage_check.dart`
- **Reporting**: LCOV format for CI integration
- **Quality Gates**: Minimum coverage thresholds

## CI/CD Pipeline (`.github/workflows/ci.yml`)

### Workflow Architecture

**Test Job**:

```yaml
Strategy: matrix testing
Node.js: v18 with npm caching
Flutter: 3.22.2 with pub caching
Parallel Execution: Both ecosystems tested simultaneously
```

**Test Execution Steps**:

1. **Environment Setup**: Node.js and Flutter SDK installation
2. **Dependency Caching**: npm and Flutter pub cache optimization
3. **Node.js Tests**: `npm run test:node` with comprehensive suite
4. **Flutter Tests**: `flutter test --coverage` with coverage reporting
5. **Static Analysis**: `flutter analyze` and `npm run lint:node`
6. **Coverage Upload**: Codecov integration for coverage tracking

**Format Check Job**:

```yaml
Code Quality Validation:
  - Prettier for JavaScript/JSON/Markdown
  - Dart format for Flutter code
  - Automated formatting verification
```

**Build Job**:

```yaml
Build Verification:
  - Flutter web build testing
  - Build artifact validation
  - Deployment readiness check
```

### Quality Gates

**Pre-commit Hooks** (Husky + lint-staged):

```json
{
  "*.{js,json,md}": "prettier --write",
  "*.dart": ["dart format", "flutter analyze"],
  "app/{lib,test}/**/*.dart": "cd app && flutter test"
}
```

**Automated Checks**:

- Code formatting consistency
- Static analysis compliance
- Test coverage maintenance
- Build process validation

### Error Handling & Reporting

**Flutter Analysis Configuration**:

- Critical errors fail CI
- Warning-level issues logged but don't block
- Configurable severity levels
- Detailed error reporting

**Test Failure Handling**:

- Detailed failure reporting
- Error aggregation across test suites
- Coverage regression detection
- Build failure notifications

## Development Workflow Integration

### Local Development

```bash
# Pre-commit validation
npm run precommit:test

# Coverage verification
npm run test-coverage

# CI alignment check
npm run verify:precommit-ci-alignment
```

### CI/CD Commands

```bash
# Node.js testing
npm run test:node

# Flutter testing with coverage
npm run test:flutter

# Combined test suite
npm run test

# Format validation
npm run format

# Linting and analysis
npm run lint
```

## Quality Metrics & Standards

### Current Status

- **Node.js Pipeline**: 174 tests passing, 0 failing
- **Flutter App**: 16 tests passing, 0 failing
- **CI Success Rate**: 100% on main branch
- **Code Coverage**: Tracked via Codecov
- **Static Analysis**: Zero critical issues

### Code Quality Standards

- **TypeScript**: Strict mode configuration
- **ESLint**: Consistent JavaScript patterns
- **Prettier**: Automated code formatting
- **Flutter Analyze**: Dart code quality validation

### Performance Monitoring

- **Build Times**: Optimized with dependency caching
- **Test Execution**: Parallel execution for speed
- **Coverage Processing**: Efficient LCOV handling
- **Artifact Management**: Automated cleanup and archiving

## Continuous Deployment Readiness

### Build Artifacts

- **Flutter Web**: Optimized production build
- **Mobile Apps**: APK/IPA generation ready
- **Node.js**: Service deployment ready
- **Documentation**: Auto-generated API docs

### Environment Management

- **Development**: Local testing with hot reload
- **Staging**: CI/CD validation environment
- **Production**: Deployment-ready builds
- **Testing**: Isolated test environments

## Troubleshooting & Maintenance

### Common CI Issues

**Flutter Analysis Failures**:

- Run `flutter analyze --no-congratulate` locally
- Fix critical errors (undefined getters, imports)
- Info-level warnings don't fail CI

**Test Coverage Regressions**:

- Check coverage reports in CI logs
- Run `flutter test --coverage` locally
- Update coverage thresholds if needed

**Build Failures**:

- Verify Flutter SDK version alignment (3.22.2)
- Check dependency compatibility
- Validate environment configuration

### Maintenance Tasks

- **Weekly**: Review test performance and flaky tests
- **Monthly**: Update dependency versions and security patches
- **Quarterly**: Review coverage thresholds and quality gates
- **As Needed**: CI configuration optimization and tooling updates

This testing infrastructure provides comprehensive quality assurance with automated validation, ensuring reliable deployments and maintainable code quality.
