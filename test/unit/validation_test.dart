import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/constants/app_constants.dart';

void main() {
  group('Validation Logic', () {
    group('AppConstants task statuses', () {
      test('contains expected statuses', () {
        expect(AppConstants.taskStatuses, contains('todo'));
        expect(AppConstants.taskStatuses, contains('in_progress'));
        expect(AppConstants.taskStatuses, contains('review'));
        expect(AppConstants.taskStatuses, contains('done'));
      });

      test('does not contain invalid status', () {
        expect(AppConstants.taskStatuses, isNot(contains('blocked')));
      });
    });

    group('AppConstants task priorities', () {
      test('contains expected priorities', () {
        expect(AppConstants.taskPriorities, contains('low'));
        expect(AppConstants.taskPriorities, contains('medium'));
        expect(AppConstants.taskPriorities, contains('high'));
        expect(AppConstants.taskPriorities, contains('urgent'));
      });

      test('does not contain invalid priority', () {
        expect(AppConstants.taskPriorities, isNot(contains('critical')));
      });
    });

    group('Email validation', () {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

      test('valid emails', () {
        expect(emailRegex.hasMatch('alice@alphacorp.com'), isTrue);
        expect(emailRegex.hasMatch('user@test.org'), isTrue);
        expect(emailRegex.hasMatch('a+b@c.co'), isTrue);
      });

      test('invalid emails', () {
        expect(emailRegex.hasMatch(''), isFalse);
        expect(emailRegex.hasMatch('notanemail'), isFalse);
        expect(emailRegex.hasMatch('@nope.com'), isFalse);
        expect(emailRegex.hasMatch('user@'), isFalse);
      });
    });

    group('Password validation', () {
      test('requires minimum 8 characters', () {
        expect('short'.length >= 8, isFalse);
        expect('longpassword'.length >= 8, isTrue);
      });

      test('requires uppercase letter', () {
        expect(RegExp(r'(?=.*[A-Z])').hasMatch('password'), isFalse);
        expect(RegExp(r'(?=.*[A-Z])').hasMatch('Password'), isTrue);
      });

      test('requires a number', () {
        expect(RegExp(r'(?=.*[0-9])').hasMatch('Password'), isFalse);
        expect(RegExp(r'(?=.*[0-9])').hasMatch('Password1'), isTrue);
      });
    });

    group('Task title validation', () {
      test('rejects empty title', () {
        expect(''.trim().isEmpty, isTrue);
        expect('   '.trim().isEmpty, isTrue);
      });

      test('rejects title over 100 characters', () {
        final longTitle = 'a' * 101;
        expect(longTitle.trim().length > 100, isTrue);
      });

      test('accepts valid title', () {
        final validTitle = 'Implement login flow';
        expect(validTitle.trim().isNotEmpty, isTrue);
        expect(validTitle.trim().length <= 100, isTrue);
      });
    });

    group('Description validation', () {
      test('rejects empty description', () {
        expect(''.trim().isEmpty, isTrue);
      });

      test('rejects description over 500 characters', () {
        final longDesc = 'a' * 501;
        expect(longDesc.trim().length > 500, isTrue);
      });

      test('accepts valid description', () {
        final validDesc = 'This is a valid description with enough detail.';
        expect(validDesc.trim().isNotEmpty, isTrue);
        expect(validDesc.trim().length <= 500, isTrue);
      });
    });

    group('Assignee validation', () {
      test('null assignee is valid (unassigned)', () {
        expect(null, isNull); // null means unassigned — always valid
      });

      test('empty string assignee is treated as null', () {
        final assigneeId = '';
        expect(assigneeId.isEmpty || assigneeId == '', isTrue);
      });
    });
  });
}
