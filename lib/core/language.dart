import 'reminder_state.dart';

/// All user-facing strings in English and Hindi.
class L {
  final AppLanguage lang;
  const L(this.lang);

  bool get isHindi => lang == AppLanguage.hindi;

  String get appName       => isHindi ? 'सिद्ध कुटुम्बकम' : 'Siddha Kutumbakam';
  String get tagline       => isHindi ? 'रुकें। श्वास लें। तटस्थ रहें।' : 'Pause. Breathe. Be Mindful & Neutral.';
  String get mindfulReminders => isHindi ? 'सजग स्मरण' : 'Mindful Reminders';

  // Exhale & Tatastha Reminders
  String get exhale        => isHindi ? 'श्वास छोड़ें' : 'Exhale';
  String get exhaleSubtitle => isHindi ? 'एक गहरी सांस लें और शांत भाव से छोड़ें।' : 'Take a conscious breath and relax.';
  String get tatastha      => isHindi ? 'तटस्थ' : 'Tatastha';
  String get tatasthaSubtitle => isHindi ? 'मन का साक्षी होने की सहज विधि।' : 'Be a calm & neutral witness to the mind.';
  
  // Backward compatibility alias
  String get taste         => tatastha;
  String get tasteSubtitle => tatasthaSubtitle;

  String get reminderOn    => isHindi ? '● रिमाइंडर चालू' : '● Reminder ON';
  String get reminderOff   => isHindi ? '○ रिमाइंडर बंद' : '○ Reminder OFF';

  String get settings      => isHindi ? 'सेटिंग्स' : 'Settings';
  String get profile       => isHindi ? 'प्रोफाइल' : 'Profile';
  String get home          => isHindi ? 'होम' : 'Home';

  String get configuration => isHindi ? 'कॉन्फ़िगरेशन' : 'Configuration';
  String get configSubtitle => isHindi ? 'अपना सजग स्मरण शेड्यूल चुनें' : 'Customize your mindful reminder schedule';

  String get exhaleConfig  => isHindi ? 'श्वास कॉन्फ़िग' : 'Exhale Config';
  String get tatasthaConfig => isHindi ? 'तटस्थ कॉन्फ़िग' : 'Tatastha Config';
  String get tasteConfig   => tatasthaConfig;

  String get playMode      => isHindi ? 'प्ले मोड' : 'Play Mode';
  String get randomly      => isHindi ? 'यादृच्छिक' : 'Randomly';
  String get randomSub     => isHindi ? 'प्रति घंटे N बार' : 'N times per hour';
  String get periodically  => isHindi ? 'नियमित अंतराल' : 'Periodically';
  String get periodicSub   => isHindi ? 'हर N मिनट में' : 'Every N minutes';
  String get timesPerHour  => isHindi ? 'प्रति घंटे बार' : 'Times per hour';
  String get intervalMin   => isHindi ? 'अंतराल (मिनट)' : 'Interval (minutes)';
  String get preset        => isHindi ? 'प्रीसेट' : 'Preset';
  String get minUnit       => isHindi ? 'मिनट' : 'min';

  String get pausePeriods  => isHindi ? 'पॉज़ अवधि' : 'Pause Periods';
  String get addPause      => isHindi ? '+ पॉज़ जोड़ें' : '+ Add Pause';
  String get noPauses      => isHindi ? 'कोई सक्रिय पॉज़ नहीं।' : 'No pauses configured.';
  String get meetingPause  => isHindi ? 'मीटिंग पॉज़' : 'Meeting Pause';
  String get meetingSub    => isHindi ? 'किसी समय के लिए ध्वनि और रिमाइंडर रोकें' : 'Pause sound & reminders for a meeting';
  String get configure     => isHindi ? 'कॉन्फ़िगर करें' : 'Configure';
  String get activePause   => isHindi ? 'पॉज़ चालू है' : 'Pause Active';
  String get pauseUntil    => isHindi ? 'तक रोका गया' : 'Paused until';
  String get resumeNow     => isHindi ? 'अभी फिर से चालू करें' : 'Resume Now';
  String get quickPause    => isHindi ? 'त्वरित पॉज़' : 'Quick Pause';
  String get pause15m      => isHindi ? '15 मिनट' : '15 min';
  String get pause30m      => isHindi ? '30 मिनट' : '30 min';
  String get pause1h       => isHindi ? '1 घंटा' : '1 hour';
  String get pause2h       => isHindi ? '2 घंटे' : '2 hours';

  String get masterPause   => isHindi ? 'सभी रिमाइंडर रोकें' : 'Pause All Reminders';
  String get masterResume  => isHindi ? 'सभी रिमाइंडर चालू करें' : 'Resume All Reminders';
  String get statusActive  => isHindi ? 'सक्रिय एवं सजग' : 'Active & Mindful';
  String get statusPaused  => isHindi ? 'रिमाइंडर रुके हुए हैं' : 'Reminders are Paused';
  String get playSound     => isHindi ? 'ध्वनि चलाएं' : 'Play Sound';
  String get stopSound     => isHindi ? 'ध्वनि रोकें' : 'Stop Sound';

  String get notifMode     => isHindi ? 'सूचना प्रकार' : 'Notification Mode';
  String get soundVibrate  => isHindi ? 'ध्वनि + कंपन' : 'Sound + Vibration';
  String get vibrateOnly   => isHindi ? 'केवल कंपन' : 'Vibration Only';
  String get silentMode    => isHindi ? 'मौन (केवल पॉप-अप)' : 'Silent (Pop-up only)';

  String get nightMode     => isHindi ? 'रात्रि मोड (साइलेंट)' : 'Night Pause';
  String get nightModeSub  => isHindi ? 'सोने के समय ध्वनि और रिमाइंडर बंद रहें' : 'Sound stops during sleep hours';
  String get nightStart    => isHindi ? 'बंद होने का समय' : 'Sleep from';
  String get nightEnd      => isHindi ? 'चालू होने का समय' : 'Wake at';
  String get nightActive   => isHindi ? 'रात्रि विराम सक्रिय' : 'Night Sleep Active';

  String get language      => isHindi ? 'भाषा' : 'Language';
  String get english       => 'English';
  String get hindi         => 'हिंदी';

  // Profile
  String get profileTitle  => isHindi ? 'साधक प्रोफाइल' : 'Sadhak Profile';
  String get sadhak        => isHindi ? 'साधक' : 'Sadhak';
  String get sadhakSub     => isHindi ? 'छोटे कदम, बेहतर जीवन' : 'Take small steps for a better you';
  String get name          => isHindi ? 'नाम' : 'Name';
  String get email         => isHindi ? 'ईमेल' : 'Email';
  String get about         => isHindi ? 'परिचय' : 'About';
  String get aboutText     => isHindi
      ? 'सिद्ध कुटुम्बकम — श्वास और तटस्थ साक्षी भाव के लिए ऑडियो रिमाइंडर ऐप।'
      : 'Siddha Kutumbakam — mindful audio reminder app for conscious breathing and neutral witness mindfulness.';
  String get stayHealthy   => isHindi ? 'स्वस्थ रहें। तटस्थ रहें!' : 'Stay Healthy. Stay Mindful & Tatastha!';
  String get quote         => isHindi
      ? '"साक्षी होने में ही मुक्ति है, तटस्थ भाव से स्वयं को देखें।"'
      : '"Awareness is freedom. Observe with a neutral, calm witness mind."';
  String get privacy       => isHindi ? 'गोपनीयता नीति' : 'Privacy Policy';
  String get terms         => isHindi ? 'नियम और शर्तें' : 'Terms & Conditions';
  String get version       => isHindi ? 'संस्करण 1.0.0' : 'Version 1.0.0';

  // Notifications
  String get exhaleNotifTitle => isHindi ? 'श्वास छोड़ें 🌬️' : 'Exhale 🌬️';
  String get exhaleNotifBody  => isHindi ? 'एक गहरी सांस बाहर छोड़ें और शांत हों।' : 'Take a slow, deep breath out and relax.';
  String get tatasthaNotifTitle => isHindi ? 'तटस्थ रहें 🧘' : 'Tatastha (Witness Mind) 🧘';
  String get tatasthaNotifBody  => isHindi ? 'मन और विचारों के प्रति तटस्थ साक्षी बनें।' : 'Be a calm, neutral witness to your thoughts.';
  String get tasteNotifTitle  => tatasthaNotifTitle;
  String get tasteNotifBody   => tatasthaNotifBody;

  String get backgroundUsage   => isHindi ? 'पृष्ठभूमि में संचालन' : 'Background Execution';
  String get backgroundActive  => isHindi ? 'पृष्ठभूमि में सक्रिय (ऐप बंद होने पर भी चलेगा)' : 'Background Active (Runs when app is closed)';
  String get backgroundOff     => isHindi ? 'पृष्ठभूमि उपयोग बंद है (ऐप बंद होने पर रुक जाएगा)' : 'Background Usage is OFF (Stops when app is closed)';
  String get allowBackground   => isHindi ? 'पृष्ठभूमि अनुमति दें' : 'Allow Background';
  String get backgroundHint    => isHindi ? 'लॉक स्क्रीन और बैकग्राउंड में बिना रुकावट रिमाइंडर प्राप्त करने के लिए अनुमति दें।' : 'Allow background usage for mindful reminders when screen is locked.';
  String get persistentNotifTitle => isHindi ? 'सिद्ध कुटुम्बकम — सजग स्मरण' : 'Siddha Kutumbakam — Mindful Reminders';
  String get persistentNotifActive => isHindi ? 'स्मरण चालू हैं • श्वास और तटस्थ रहें' : 'Reminders Active • Breathe & Be Tatastha';
  String get persistentNotifPaused => isHindi ? 'स्मरण रुके हुए हैं • फिर से चालू करने के लिए टैप करें' : 'Reminders Paused • Tap to Resume';
  String get persistentNotifPlaying => isHindi ? 'ध्वनि बज रही है • शांत भाव से सुनें' : 'Mindful Audio Playing • Listen & Be Present';

  String get tipText       => isHindi
      ? 'मीटिंग में हैं या विश्राम कर रहे हैं? नीचे दिए गए मीटिंग पॉज़ या रात्रि मोड से ध्वनि रोकें।'
      : 'In a meeting or sleeping? Use Meeting Pause or Night Pause below to stop the sound.';
}

