import 'package:stream_chat_jaspr/src/util/formatting.dart';
import 'package:test/test.dart';

void main() {
  group('formatTimeOfDay', () {
    test('pads hours and minutes', () {
      final date = DateTime(2026, 8, 21, 9, 5);
      expect(formatTimeOfDay(date), '09:05');
    });

    test('uses 24 hour clock', () {
      expect(formatTimeOfDay(DateTime(2026, 8, 21, 23, 59)), '23:59');
    });
  });

  group('formatChannelTimestamp', () {
    test('shows a time for today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      expect(formatChannelTimestamp(today), '14:30');
    });

    test('shows "Yesterday" for the previous day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(formatChannelTimestamp(yesterday), 'Yesterday');
    });

    test('shows a weekday within the last week', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(
        formatChannelTimestamp(threeDaysAgo),
        equals(
          [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ][threeDaysAgo.weekday - 1],
        ),
      );
    });

    test('shows a numeric date beyond a week', () {
      final old = DateTime(2024, 3, 9, 12);
      expect(formatChannelTimestamp(old), '09/03/2024');
    });
  });

  group('formatDateDivider', () {
    test('labels today and yesterday', () {
      expect(formatDateDivider(DateTime.now()), 'Today');
      expect(
        formatDateDivider(DateTime.now().subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });

    test('omits the year for the current year', () {
      final thisYear = DateTime(DateTime.now().year, 1, 15);
      expect(formatDateDivider(thisYear), 'January 15');
    });

    test('includes the year for other years', () {
      expect(formatDateDivider(DateTime(2019, 12, 3)), 'December 3, 2019');
    });
  });

  group('isSameDay', () {
    test('is true across different times of one day', () {
      expect(
        isSameDay(DateTime(2026, 8, 21, 0, 1), DateTime(2026, 8, 21, 23, 59)),
        isTrue,
      );
    });

    test('is false across midnight', () {
      expect(
        isSameDay(DateTime(2026, 8, 21, 23, 59), DateTime(2026, 8, 22, 0, 1)),
        isFalse,
      );
    });
  });

  group('initialsFor', () {
    test('takes the first two letters of a single word', () {
      expect(initialsFor('Alice'), 'AL');
    });

    test('takes first and last initials of multiple words', () {
      expect(initialsFor('Ada Lovelace'), 'AL');
      expect(initialsFor('Jean Luc Picard'), 'JP');
    });

    test('collapses extra whitespace', () {
      expect(initialsFor('  Ada   Lovelace  '), 'AL');
    });

    test('falls back to a question mark', () {
      expect(initialsFor(null), '?');
      expect(initialsFor(''), '?');
      expect(initialsFor('   '), '?');
    });

    test('handles a single character name', () {
      expect(initialsFor('x'), 'X');
    });
  });

  group('hueFor', () {
    test('is stable for the same seed', () {
      expect(hueFor('user-1'), hueFor('user-1'));
    });

    test('stays within the hue range', () {
      for (final seed in ['', 'a', 'user-42', 'a much longer identifier']) {
        expect(hueFor(seed), inInclusiveRange(0, 359));
      }
    });
  });
}
