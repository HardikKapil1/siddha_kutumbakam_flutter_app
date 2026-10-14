import 'package:flutter_test/flutter_test.dart';
import 'package:siddha_kutumbakam_reminder/core/language.dart';
import 'package:siddha_kutumbakam_reminder/core/reminder_state.dart';

void main() {
  test('Language translations test', () {
    final en = L(AppLanguage.english);
    final hi = L(AppLanguage.hindi);

    expect(en.appName, 'Siddha Kutumbakam');
    expect(hi.appName, 'सिद्ध कुटुम्बकम');
    expect(en.masterPause, 'Pause All Reminders');
    expect(hi.masterPause, 'सभी रिमाइंडर रोकें');
  });
}
