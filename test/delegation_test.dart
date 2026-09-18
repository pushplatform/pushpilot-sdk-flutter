import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Verification tests that retry and deduplication are fully delegated to native SDKs
///
/// These tests are meta-tests: they verify the ABSENCE of certain patterns in the code.
void main() {
  group('Retry/Deduplication Delegation', () {
    test('No retry logic in Dart source code', () async {
      final libDir = Directory('lib');
      final dartFiles = await libDir
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .cast<File>()
          .toList();

      for (final file in dartFiles) {
        final content = await file.readAsString();

        // Check for retry patterns
        expect(
          content.toLowerCase(),
          isNot(matches(r'retry.*count|retry.*attempt|exponential.*back')),
          reason: '${file.path} should not contain retry logic',
        );

        // Check for Timer-based retry
        if (content.contains('Timer')) {
          expect(
            content,
            isNot(contains('Timer.periodic')),
            reason: '${file.path} should not use Timer for retry',
          );
        }
      }
    });

    test('No deduplication logic in Dart source code', () async {
      final libDir = Directory('lib');
      final dartFiles = await libDir
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .cast<File>()
          .toList();

      for (final file in dartFiles) {
        final content = await file.readAsString();

        // Check for deduplication patterns
        expect(
          content,
          isNot(matches(r'Set<.*messageId|_seen.*messages|_processed.*ids')),
          reason: '${file.path} should not contain deduplication logic',
        );

        // Check for caching of message IDs
        expect(
          content,
          isNot(matches(r'Map<String.*messageId|cache.*notification')),
          reason: '${file.path} should not cache messages for deduplication',
        );
      }
    });

    test('README documents delegation strategy', () async {
      final readme = File('README.md');
      final content = await readme.readAsString();

      // Verify delegation is documented
      expect(
        content,
        contains('thin wrapper'),
        reason: 'README should describe SDK as thin wrapper',
      );

      expect(
        content,
        matches(RegExp(r'retry.*native|native.*retry', caseSensitive: false)),
        reason: 'README should document that retry is in native layer',
      );

      expect(
        content,
        matches(RegExp(r'deduplication.*native|native.*deduplication',
            caseSensitive: false)),
        reason: 'README should document that deduplication is in native layer',
      );

      expect(
        content,
        contains('NO retry logic in Dart'),
        reason: 'README should explicitly state no Dart retry logic',
      );
    });
  });
}
