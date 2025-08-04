# Test Serialization Issue Fix

## Problem Description

The test `contentmanager-nested.test.js` was failing in GitHub Actions with the error:

```
Unable to deserialize cloned data due to invalid or unsupported version.
```

This error occurs due to Node.js version compatibility issues with the built-in test runner's serialization mechanism, specifically when using `node:test` in CI environments.

## Root Cause Analysis

1. **Node.js Version Mismatch**: Different patch versions of Node.js 18 can have subtle differences in the `structuredClone` implementation used by the test runner.

2. **Serialization Protocol Issues**: The built-in test runner uses inter-process communication that relies on data serialization, which can fail when there are version mismatches between the main process and worker processes.

3. **CI Environment Differences**: GitHub Actions runners may have different Node.js patch versions or environment configurations that trigger edge cases in the serialization process.

## Solutions Implemented

### 1. Pinned Node.js Version

Updated `.github/workflows/ci.yml` to use a specific Node.js version:

```yaml
node-version: "18.19.1" # Instead of '18'
```

### 2. Enhanced Test Runner

Updated `tests/run-tests.js` with:

- Better error handling for serialization failures
- Automatic fallback to sequential test execution
- Increased memory allocation with `NODE_OPTIONS: "--max-old-space-size=4096"`

### 3. Simple Test Runner Fallback

Created `tests/run-tests-simple.js` that:

- Runs tests one by one to avoid parallel execution issues
- Provides a reliable fallback when the main runner fails
- Added as `npm run test:node:simple`

### 4. Robust Test Version

Created `tests/contentmanager-nested-robust.test.js` with:

- Simplified test structure to minimize serialization complexity
- Same test coverage as the original
- More resilient to environment differences

### 5. GitHub Actions Fallback

Added a fallback step in CI that runs if the main test step fails:

```yaml
- name: Run Node.js tests with simple runner (fallback)
  if: failure()
  run: npm run test:node:simple
```

## Usage

### Local Development

```bash
# Use the enhanced runner (recommended)
npm run test:node

# Use the simple runner if you encounter issues
npm run test:node:simple

# Run the robust test version
node --test tests/contentmanager-nested-robust.test.js
```

### CI/CD

The GitHub Actions workflow will:

1. Try the enhanced test runner first
2. Automatically fall back to the simple runner if needed
3. Provide detailed logging for debugging

## Prevention

To prevent similar issues in the future:

1. **Pin Node.js versions** in both local development and CI
2. **Use the enhanced test runner** which handles serialization issues gracefully
3. **Keep test data simple** and avoid complex objects that might cause serialization issues
4. **Monitor Node.js updates** and test thoroughly when upgrading

## Debugging

If you encounter similar issues:

1. Check Node.js versions: `node -v`
2. Try the simple runner: `npm run test:node:simple`
3. Run tests individually: `node --test tests/specific-test.js`
4. Check for complex objects in test data that might not serialize properly

## Files Modified

- `.github/workflows/ci.yml` - Pinned Node.js version and added fallback
- `tests/run-tests.js` - Enhanced with error handling and fallback
- `tests/run-tests-simple.js` - New simple runner
- `tests/contentmanager-nested-robust.test.js` - Robust test version
- `package.json` - Added new test script
- `TEST_SERIALIZATION_FIX.md` - This documentation

## Testing the Fix

To verify the fix works:

1. **Local testing**: Run `npm run test:node` and `npm run test:node:simple`
2. **CI testing**: Push changes and check GitHub Actions logs
3. **Fallback testing**: The CI will automatically try the fallback if the main runner fails

The enhanced test runner should handle the serialization issues gracefully, and the fallback options ensure tests can still run even if there are environment-specific issues.
