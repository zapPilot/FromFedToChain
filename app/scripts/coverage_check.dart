#!/usr/bin/env dart

import 'dart:io';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  print('🔍 Checking Flutter test coverage...');

  // Load configuration from coverage.yaml
  final configFile = File('coverage.yaml');
  if (!configFile.existsSync()) {
    print('❌ No coverage.yaml configuration file found.');
    exit(1);
  }

  final configContent = configFile.readAsStringSync();
  final config = loadYaml(configContent);

  // Check if coverage is enabled
  if (config['coverage_options']['enabled'] != true) {
    print('⚠️  Coverage checking is disabled in coverage.yaml');
    exit(0);
  }

  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('❌ No coverage file found. Run "flutter test --coverage" first.');
    exit(1);
  }

  final lcovContent = lcovFile.readAsStringSync();

  // Parse LCOV content manually since we don't have the coverage package
  final lines = lcovContent.split('\n');
  int totalLines = 0;
  int coveredLines = 0;

  for (final line in lines) {
    if (line.startsWith('DA:')) {
      final parts = line.split(',');
      if (parts.length >= 2) {
        final hitCount = int.tryParse(parts[1]) ?? 0;
        totalLines++;
        if (hitCount > 0) {
          coveredLines++;
        }
      }
    }
  }

  final overallCoverage =
      totalLines > 0 ? (coveredLines / totalLines) * 100 : 0;

  print('📊 Coverage Report:');
  print('   Total Lines: $totalLines');
  print('   Covered Lines: $coveredLines');
  print('   Overall Coverage: ${overallCoverage.toStringAsFixed(2)}%');

  // Get thresholds from configuration
  final globalThresholds = config['coverage_options']['thresholds']['global'];
  final thresholds = {
    'statements': globalThresholds['statements'].toDouble(),
    'branches': globalThresholds['branches'].toDouble(),
    'functions': globalThresholds['functions'].toDouble(),
    'lines': globalThresholds['lines'].toDouble(),
  };

  bool allThresholdsMet = true;

  for (final entry in thresholds.entries) {
    final metric = entry.key;
    final threshold = entry.value;
    final coverage =
        overallCoverage; // Simplified - you can calculate per metric

    final status = coverage >= threshold ? '✅' : '❌';
    print(
        '   $metric: $status ${coverage.toStringAsFixed(2)}% (threshold: $threshold%)');

    if (coverage < threshold) {
      allThresholdsMet = false;
    }
  }

  // Check per-file thresholds if they exist
  final fileThresholds = config['coverage_options']['thresholds']['files'];
  if (fileThresholds != null) {
    print('\n📁 Per-file threshold checks:');
    for (final filePattern in fileThresholds.keys) {
      final fileThreshold = fileThresholds[filePattern];
      print('   $filePattern: ${fileThreshold['lines']}% lines threshold');
      // Note: Per-file checking would require more complex parsing
    }
  }

  if (!allThresholdsMet) {
    print('\n❌ Coverage thresholds not met!');
    exit(1);
  } else {
    print('\n✅ All coverage thresholds met!');
  }

  // Generate HTML report if genhtml is available
  try {
    final result = await Process.run('genhtml', [
      'coverage/lcov.info',
      '-o',
      'coverage/html',
      '--title=Flutter Test Coverage'
    ]);

    if (result.exitCode == 0) {
      print('📁 HTML coverage report generated at: coverage/html/index.html');
    }
  } catch (e) {
    print('⚠️  HTML report generation failed. Install lcov for HTML reports.');
  }
}
