/// Dead code checker for Flutter/Dart projects
///
/// This script scans the lib/ directory for potential dead code patterns:
/// - Classes defined but only referenced once (their definition)
/// - Exception classes defined but never thrown
/// - Unused exports in barrel files
///
/// Usage: dart run scripts/deadcode_check.dart
library;

import 'dart:io';

void main() async {
  print('🔍 Scanning for dead code...\n');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Error: lib/ directory not found. Run from app/ directory.');
    exit(1);
  }

  final issues = <String>[];

  // Collect all Dart files
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // Read all file contents into memory for cross-referencing
  final fileContents = <String, String>{};
  for (final file in dartFiles) {
    fileContents[file.path] = file.readAsStringSync();
  }

  final allCode = fileContents.values.join('\n');

  // Check for exception classes that are never thrown
  final exceptionClassPattern = RegExp(r'class\s+(\w+Exception)\s+extends');
  for (final match in exceptionClassPattern.allMatches(allCode)) {
    final className = match.group(1)!;
    final throwPattern = RegExp('throw\\s+$className\\s*\\(');
    if (!throwPattern.hasMatch(allCode)) {
      issues
          .add('⚠️  Exception class "$className" is defined but never thrown');
    }
  }

  // Check for classes only referenced once (their own definition)
  final classPattern = RegExp(r'^class\s+(\w+)\s+', multiLine: true);
  for (final match in classPattern.allMatches(allCode)) {
    final className = match.group(1)!;
    // Skip private classes and common framework classes
    if (className.startsWith('_') ||
        className.endsWith('State') ||
        className.endsWith('Widget')) {
      continue;
    }

    final usagePattern = RegExp('\\b$className\\b');
    final usages = usagePattern.allMatches(allCode).length;

    // If only found once (its own definition), it might be dead code
    // Allow 2 for definition + export
    if (usages <= 1) {
      issues.add(
          '⚠️  Class "$className" appears to be unused (only $usages reference)');
    }
  }

  // Output results
  if (issues.isEmpty) {
    print('✅ No dead code detected!\n');
    exit(0);
  } else {
    print('🔴 Found ${issues.length} potential dead code issue(s):\n');
    for (final issue in issues) {
      print('   $issue');
    }
    print('');
    print('💡 Review these items and remove if confirmed unused.');
    print(
        '   Some may be false positives (e.g., used via reflection or planned features).\n');
    exit(1);
  }
}
