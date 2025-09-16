#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Enhanced Flutter test runner with better output formatting
/// Usage: dart test_runner.dart [--failures-only] [--no-coverage]
void main(List<String> args) async {
  final showFailuresOnly = args.contains('--failures-only');
  final noCoverage = args.contains('--no-coverage');

  print('🧪 Running Flutter Tests with Enhanced Output\n');

  final coverageFlag = noCoverage ? '' : '--coverage';

  // Run tests with JSON reporter for parsing
  final process = await Process.start(
    'flutter',
    ['test', '--reporter', 'json', coverageFlag],
    mode: ProcessStartMode.normal,
  );

  int passed = 0;
  int failed = 0;
  List<String> failedTests = [];
  List<String> failureDetails = [];

  await for (String line
      in process.stdout.transform(utf8.decoder).transform(LineSplitter())) {
    try {
      final json = jsonDecode(line);

      if (json['type'] == 'testDone') {
        final result = json['result'];
        final testName = json['testName'] ?? 'Unknown test';

        if (result == 'success') {
          passed++;
          if (!showFailuresOnly) {
            print('✅ $testName');
          }
        } else if (result == 'error') {
          failed++;
          failedTests.add(testName);
          print('❌ $testName');
        }
      } else if (json['type'] == 'error') {
        final error = json['error'];
        failureDetails.add(error);
        print('   Error: $error');
      }
    } catch (e) {
      // Ignore non-JSON lines (debug output)
    }
  }

  // Print summary
  print('\n📊 Test Results Summary:');
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');

  if (failed > 0) {
    print('\n🔍 Failed Tests:');
    for (int i = 0; i < failedTests.length; i++) {
      print('  ${i + 1}. ${failedTests[i]}');
    }
  }

  final exitCode = await process.exitCode;
  exit(exitCode);
}
